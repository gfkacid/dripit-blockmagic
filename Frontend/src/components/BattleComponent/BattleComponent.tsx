import styles from "./BattleComponent.module.css";
import { Battle } from "../../lib/types/Battle.type";

type Props = {
  battle: Battle;
};

const BattleComponent = (props: Props) => {
  const { battle } = props;
  return (
    <div className={styles.BattleComponent}>
      <div>
        <div className={styles.row}>
          <div className={styles.key}>Id:</div>
          <div className={styles.value}>{battle.id}</div>
        </div>
        <div className={styles.row}>
          <div className={styles.key}>Side A:</div>
          <div className={styles.value}>{battle.sideA_id}</div>
        </div>
        <div className={styles.row}>
          <div className={styles.key}>Side B:</div>
          <div className={styles.value}>{battle.sideB_id}</div>
        </div>
        <div className={styles.row}>
          <div className={styles.key}>Amount A:</div>
          <div className={styles.value}>{battle.amountA}</div>
        </div>
        <div className={styles.row}>
          <div className={styles.key}>Amount B:</div>
          <div className={styles.value}>{battle.amountB}</div>
        </div>
        <div className={styles.row}>
          <div className={styles.key}>Total:</div>
          <div className={styles.value}>{battle.total}</div>
        </div>
      </div>
    </div>
  );
};

export default BattleComponent;
