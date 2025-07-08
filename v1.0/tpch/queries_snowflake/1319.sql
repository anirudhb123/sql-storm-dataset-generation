
WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name, 
           RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank_within_nation
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
),
OrderSummary AS (
    SELECT o.o_custkey, COUNT(DISTINCT o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM orders o
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= DATE '1995-01-01'
    GROUP BY o.o_custkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, os.total_orders, os.total_spent
    FROM customer c
    JOIN OrderSummary os ON c.c_custkey = os.o_custkey
    WHERE os.total_spent > 10000
),
PartStatistics AS (
    SELECT p.p_partkey, AVG(ps.ps_supplycost) AS avg_supply_cost,
           SUM(l.l_quantity) AS total_quantity_sold
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE p.p_size < 50
    GROUP BY p.p_partkey
)
SELECT hvc.c_name AS customer_name, hvc.total_orders, hvc.total_spent,
       ps.p_partkey, ps.avg_supply_cost, ps.total_quantity_sold,
       rd.r_name AS region, 
       COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE 0 END), 0) AS total_returns
FROM HighValueCustomers hvc
JOIN lineitem l ON hvc.c_custkey = l.l_orderkey
JOIN PartStatistics ps ON l.l_partkey = ps.p_partkey
JOIN region rd ON hvc.c_custkey = (SELECT MIN(c.c_custkey) FROM customer c WHERE c.c_nationkey = rd.r_regionkey)
LEFT JOIN SupplierDetails sd ON sd.rank_within_nation <= 3
GROUP BY hvc.c_name, hvc.total_orders, hvc.total_spent, ps.p_partkey, ps.avg_supply_cost, ps.total_quantity_sold, rd.r_name
ORDER BY hvc.total_spent DESC, hvc.total_orders ASC;
