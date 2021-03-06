open Prelude

module type I = sig
  type 'a t
  val map : ('a -> 'b) -> 'a t -> 'b t
end

module type S = sig
  type 'a t
  include I with type 'a t := 'a t

  val void : 'a t -> unit t

  module Infix : sig
    val (<$>) : ('a -> 'b) -> 'a t -> 'b t
    val (>>|) : ('a -> 'b) -> 'a t -> 'b t
    val (<$)  : 'a -> 'b t -> 'a t
    val ($>)  : 'a t -> 'b -> 'b t
  end
end

module Make (F : I) : S with type 'a t := 'a F.t = struct
  let map = F.map
  let void t = F.map ignore t

  module Infix = struct
    let (<$>) = F.map
    let (>>|) = F.map
    let (<$) a t = F.map (const a) t
    let ($>) t b = F.map (const b) t
  end
end

module type T = sig
  module From : I
  module Into : I
  val trans : 'a From.t -> 'a Into.t
end

module type I2 = sig
  type ('a, 'e) t
  val map : ('a -> 'b) -> ('a, 'e) t -> ('b, 'e) t
end

module type S2 = sig
  type ('a, 'e) t
  include I2 with type ('a, 'e) t := ('a, 'e) t
  module Infix : sig
    val (<$>) : ('a -> 'b) -> ('a, 'e) t -> ('b, 'e) t
  end
end

module Make2 (F : I2) : S2 with type ('a, 'e) t := ('a, 'e) F.t = struct
  let map = F.map

  module Infix = struct
    let (<$>) = F.map
  end
end

module Coproduct = struct
  module type S = sig
    type 'a left
    type 'a right
    type 'a t =
      | Left  of 'a left
      | Right of 'a right

    include S with type 'a t := 'a t

    val lift_left  : 'a left  -> 'a t
    val lift_right : 'a right -> 'a t
  end

  module Make (L : I) (R : I) : S
    with type 'a left  := 'a L.t
     and type 'a right := 'a R.t = struct
    module F = struct
      type 'a t =
        | Left  of 'a L.t
        | Right of 'a R.t

      let map f = function
        | Left m  -> Left  (L.map f m)
        | Right m -> Right (R.map f m)
    end

    include F
    include Make (F)

    let lift_left  a = Left  a
    let lift_right a = Right a
  end
end
