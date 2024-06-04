export class Battle {
  id: number;
  type: number;
  status: number;
  sideA_id: number;
  sideB_id: number;
  amountA: bigint;
  amountB: bigint;
  total: bigint;
  start_date: Date;
  end_date: Date;
  created_by: number;
}
