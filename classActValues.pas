unit classActValues;

interface

type
  TActValues = class
    ATK : Integer;
    Movement : Integer;

    constructor Create(nATK : Integer; nMovement : Integer);
  end;

implementation

constructor TActValues.Create(nATK : Integer; nMovement : Integer);
begin
  ATK := nATK;
  Movement := nMovement;
end;

end.
