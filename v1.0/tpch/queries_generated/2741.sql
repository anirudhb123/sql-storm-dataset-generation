WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
),

OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2022-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
),

CustomerRegion AS (
    SELECT c.c_custkey, c.c_name, n.n_regionkey
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
)

SELECT cr.n_regionkey,
       COUNT(DISTINCT od.o_orderkey) AS total_orders,
       SUM(sd.total_supply_cost) AS total_supply_cost,
       AVG(sd.s_acctbal) AS avg_account_balance
FROM CustomerRegion cr
LEFT JOIN OrderSummary od ON cr.c_custkey = od.o_custkey
LEFT JOIN SupplierDetails sd ON cr.n_regionkey = (SELECT r.r_regionkey 
                                                    FROM region r 
                                                    WHERE r.r_name = (SELECT DISTINCT n.n_name 
                                                                      FROM nation n 
                                                                      WHERE n.n_nationkey = cr.n_regionkey))
WHERE (sd.s_acctbal IS NOT NULL OR sd.total_supply_cost > 10000)
GROUP BY cr.n_regionkey
HAVING COUNT(DISTINCT od.o_orderkey) > 5
ORDER BY total_orders DESC, avg_account_balance DESC;
