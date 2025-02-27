WITH RecurringOrders AS (
    SELECT o.o_orderkey, 
           COUNT(DISTINCT o.o_orderdate) OVER (PARTITION BY o.o_custkey) AS order_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('F', 'O') AND l.l_shipmode LIKE 'AIR%'
    GROUP BY o.o_orderkey, o.o_custkey
),
CustomerSpending AS (
    SELECT c.c_custkey, 
           c.c_name, 
           COALESCE(SUM(ro.total_spent), 0) AS total_spent,
           RANK() OVER (ORDER BY COALESCE(SUM(ro.total_spent), 0) DESC) AS spending_rank
    FROM customer c
    LEFT JOIN RecurringOrders ro ON c.c_custkey = ro.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierPartInfo AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT p.p_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           total_supply_cost,
           RANK() OVER (ORDER BY total_supply_cost DESC) AS rank_supplier
    FROM SupplierPartInfo s
    WHERE part_count > 1
),
FinalReport AS (
    SELECT cs.c_custkey, 
           cs.c_name,
           cs.total_spent, 
           COALESCE(ts.s_name, 'No Supplier') AS preferred_supplier
    FROM CustomerSpending cs
    LEFT JOIN TopSuppliers ts ON ts.rank_supplier = 1 AND cs.total_spent > 1000
)
SELECT 
    fr.c_custkey,
    fr.c_name, 
    fr.total_spent,
    CASE 
        WHEN fr.total_spent IS NULL THEN 'Ideal Customer'
        ELSE CASE 
            WHEN fr.total_spent < 500 THEN 'Low Value Customer'
            WHEN fr.total_spent BETWEEN 500 AND 1500 THEN 'Medium Value Customer'
            WHEN fr.total_spent > 1500 THEN 'High Value Customer'
            ELSE 'Unknown Category'
        END
    END AS customer_category,
    fr.preferred_supplier
FROM FinalReport fr
WHERE fr.total_spent IS NOT NULL
UNION ALL
SELECT 
    cs.c_custkey,
    cs.c_name, 
    cs.total_spent,
    'Potential Customer' AS customer_category,
    'No Supplier' AS preferred_supplier
FROM CustomerSpending cs
WHERE cs.total_spent < 1000
ORDER BY total_spent DESC NULLS LAST;
