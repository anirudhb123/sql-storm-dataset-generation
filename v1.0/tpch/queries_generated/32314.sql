WITH RECURSIVE RegionSupplier AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, r.r_name AS region_name, s.s_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE r.r_name = 'Europe'
    UNION ALL
    SELECT s.s_suppkey, s.s_name, n.n_name, r.r_name, s.s_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN RegionSupplier rs ON s.s_nationkey = rs.n_nationkey
    WHERE r.r_name <> rs.region_name
),
PartSupplierStats AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_available_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000
),
OrderLineStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price, COUNT(l.l_orderkey) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
)
SELECT r.region_name, 
       rs.s_name,
       p.p_name,
       SUM(ols.total_price) AS total_sales,
       COUNT(DISTINCT ols.o_orderkey) AS order_count,
       hf.c_name AS high_value_customer_name,
       hf.c_acctbal AS customer_balance,
       COALESCE(p.total_available_qty,0) AS total_available_qty,
       COALESCE(p.avg_supply_cost,0) AS avg_supply_cost
FROM RegionSupplier rs
LEFT JOIN PartSupplierStats p ON rs.s_suppkey = p.ps_suppkey
LEFT JOIN OrderLineStats ols ON p.ps_partkey = ols.o_orderkey
LEFT JOIN HighValueCustomers hf ON ols.item_count > 10
GROUP BY r.region_name, rs.s_name, p.p_name, hf.c_name, hf.c_acctbal
HAVING SUM(ols.total_price) > 5000
ORDER BY total_sales DESC, customer_balance DESC;
