unit classTile;

interface
uses GameValues, classActValues,
  FMX.Objects, FMX.StdCtrls, FMX.Types, UITypes, Classes, SysUtils, Types;

const
  iGrass = 0;
  iRiver = 1;
  iMountain = 2;

  iNorth = 0;
  iEast  = 1;
  iSouth = 2;
  iWest  = 3;

type
  // Due to the way delphi handles circular "uses", cannot have the tile keep
  // track of the unit occupying it and also have the unit keep track of the tile
  // it occupies, so some relatively weird stuff has to be done with attacks

  // Also can't have units in the interface at all so no using units as parameters
  TTile = class(TRectangle)
  private
    cTerrain  : Integer;
    cCoords : TPoint;

    cMoveDistFromSelected : Integer;
    cATKDistFromSelected : Integer;
    cMoveable : Boolean;
    cAttackable: Boolean;
    cHasUnit : Boolean;

    cMovementCircle : TCircle;
    cAttackRect : TRectangle;

    cTestLabel : TLabel;

    procedure OnTileClick(Sender : TObject);
    procedure SetTileDistance(Range: TActValues; const Dist : Integer;
    AP : Integer; UnitClass : String; Start : TTile);
  protected
    cNeighbours : TList;
  published

  property TestLabel : TLabel
      read cTestLabel write cTestLabel;

  
  
    property Terrain : Integer
      read cTerrain;
    property Coords : TPoint
      read cCoords;

    property Neighbours : TList
      read cNeighbours;

    property MoveDistFromSelected : Integer
      read cMoveDistFromSelected write cMoveDistFromSelected;
    property ATKDistFromSelected : Integer
      read cATKDistFromSelected write cATKDistFromSelected;
    property Moveable : Boolean
      read cMoveable write cMoveable;
    property Attackable : Boolean
      read cAttackable write cAttackable;
    property HasUnit : Boolean
      read cHasUnit write cHasUnit;
    property MovementCircle : TCircle
      read cMovementCircle write cMovementCircle;
    property AttackRect : TRectangle
      read cAttackRect write cAttackRect;

    constructor Create(AOwner : TComponent; XPos : Integer; YPos : Integer);
    procedure SetTerrain(TerrainType : Integer);
    procedure SetNorth(Tile : TTile);
    procedure SetEast(Tile : TTile);
    procedure SetSouth(Tile : TTile);
    procedure SetWest(Tile : TTile);
    function North : TTile;
    function West : TTile;
    function South : TTile;
    function East : TTile;
    procedure SetAttackRect;
    procedure GetTileDistances(Range: TActValues; Dist : Integer; AP : Integer; UnitClass : String;  Start : TTile);
    function IsLineTo(UnitTile : TTile) : Boolean;
  end;

implementation
uses Main, classWorld;

  procedure TTile.OnTileClick(Sender: TObject);
  begin
    if Assigned(SelectedUnit) and (Moveable) then
    begin
      SelectedUnit.Move(Self, MoveDistFromSelected);
    end
    else MainForm.Deselect;
  end;

  constructor TTile.Create(AOwner : TComponent; XPos : Integer; YPos : Integer);
  var
    I : Integer;
  begin
    Inherited Create(AOwner);
    Width := TileWidth;
    Height := TileHeight;
    Visible := True;

    OnClick := OnTileClick;

    cTerrain := iGrass;
    Fill.Color := ColorGrass;

    cCoords := Point(XPos, YPos);
    Position.X := XPos * TileWidth;
    Position.Y := YPos * TileHeight;

    MoveDistFromSelected := -1;
    ATKDistFromSelected := -1;

    cNeighbours := TList.Create;
    for I := 0 to 3 do cNeighbours.Add(nil);

    Moveable := False;
    Attackable := False;
    HasUnit := False;

    testLabel := TLabel.Create(Self);
    testLabel.Parent := Self;
    testLabel.Align := TAlignLayout.None;
    testLabel.StyledSettings := testLabel.StyledSettings - [TStyledSetting.Size];
    testLabel.TextSettings.Font.Size := 25;
    testLabel.Text := MoveDistFromSelected.ToString;
    testLabel.BringToFront;
    testLabel.Visible := False;
  end;

  procedure TTile.SetTerrain(TerrainType : Integer);
  begin
    cTerrain := TerrainType;
    if TerrainType = iGrass then
    begin
      Fill.Color := ColorGrass;
    end
    else
    if TerrainType = iRiver then
    begin
      Fill.Color := ColorRiver;
    end
    else
    if TerrainType = iMountain then
    begin
      Fill.Color := ColorMountain;
    end;
  end;

  procedure TTile.SetNorth(Tile : TTile);
  begin
    Neighbours[iNorth] := Tile;
    Tile.Neighbours[iSouth] := Self;
  end;

  procedure TTile.SetEast(Tile : TTile);
  begin
    Neighbours[iEast] := Tile;
    Tile.Neighbours[iWest] := Self;
  end;

  procedure TTile.SetSouth(Tile : TTile);
  begin
    Neighbours[iSouth] := Tile;
    Tile.Neighbours[iNorth] := Self;
  end;

  procedure TTile.SetWest(Tile : TTile);
  begin
    Neighbours[iWest] := Tile;
    Tile.Neighbours[iEast] := Self;
  end;

  function TTile.North : TTile;
  begin
    Result := Neighbours[iNorth];
  end;

  function TTile.West : TTile;
  begin
    Result := Neighbours[iWest];
  end;

  function TTile.South : TTile;
  begin
    Result := Neighbours[iSouth];
  end;

  function TTile.East : TTile;
  begin
    Result := Neighbours[iEast];
  end;

  // Used in SetTileDistance
  procedure TTile.SetAttackRect;
  var
    Rect : TRectangle;
  begin
    Rect := World.GetAvailableAttack;
    Rect.Parent := Self;
    Rect.OnClick := OnTileClick;
    AttackRect := Rect;
  end;

  // Create a circle on this tile to show that it can be moved to
  // Also do this for any tiles in range-1 of this tile
  procedure TTile.SetTileDistance(Range: TActValues; const Dist : Integer;
   AP : Integer; UnitClass : String; Start : TTile);
  var
    Circle : TCircle;
    newDist : Integer;

    testLabel : TLabel;
  begin
    newDist := Dist;
    // Grass costs 1 to go into, river costs 2, mountain costs 2
    if Terrain = iGrass then newDist :=  newDist + 1
    else if Terrain = iRiver then newDist := newDist + 2
    else if Terrain = iMountain then newDist := newDist + 2;

    // Cannot move to a tile that already has a unit
    if HasUnit then
    begin
      newDist := 100;
      //if UnitClass = 'TCavalry' then ATKDistFromSelected := Range.ATK;
    end;

    if (MoveDistFromSelected < 0) or
    (newDist < MoveDistFromSelected)
    then
    MoveDistFromSelected := newDist;

    if (Range.Movement >= MoveDistFromSelected) and (not HasUnit) then
    begin
      if not Assigned(MovementCircle) then
      begin
        Circle := World.GetAvailableMove;
        Circle.Parent := Self;
        Circle.OnClick := OnTileClick;
        MovementCircle := Circle;
      end;
      Moveable := True;
    end;

    newDist := MoveDistFromSelected;
    GetTileDistances(Range, newDist, AP, UnitClass, Start);
  end;

  procedure TTile.GetTileDistances(Range : TActValues; Dist : Integer; AP : Integer; UnitClass : String; Start : TTile);
  var
    I: Integer;
    CurrTile : TTile;
  begin
    // SetTileDistance for each Neighbour
    for I := 0 to Neighbours.Count - 1 do
    begin
      if Assigned(Neighbours[I]) then
      begin
        CurrTile := Neighbours[I];
        // If tile not explored yet:
        if (CurrTile.MoveDistFromSelected < 0)
        // or If tile is explored and distance is less than current best distance:
        or (CurrTile.MoveDistFromSelected > MoveDistFromSelected + 1)
        then
        begin
          CurrTile.SetTileDistance(Range, Dist, AP, UnitClass, Start);
        end;
      end;
    end;
  end;

  // Determines if there is an straight line to the tile (obstacles like rivers are OK)
  function TTile.IsLineTo(UnitTile : TTile) : Boolean;
  begin
    // No vertical movement
    if not ((Self.Coords.Y > UnitTile.Coords.Y) or (Self.Coords.Y < UnitTile.Coords.Y)) then
    begin
      Result := True;
    end
    else
    // No Horizontal Movement
    if not ((Self.Coords.X > UnitTile.Coords.X) or (Self.Coords.X < UnitTile.Coords.X)) then
    begin
      Result := True;
    end
    // both horizontal and vertical movement, not a straight line
    else Result := False;
  end;

end.
