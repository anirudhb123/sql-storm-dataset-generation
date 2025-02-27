WITH supplier_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    INNER JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
high_value_customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_extended_price
    FROM lineitem l
    WHERE l.l_shipdate > '2023-01-01'
    GROUP BY l.l_orderkey
)
SELECT n.n_name, sd.s_name, hvc.c_name, 
       COALESCE(SUM(ls.total_extended_price), 0) AS total_sales,
       COALESCE(sd.total_supply_cost, 0) AS total_supply_cost
FROM nation n
LEFT JOIN supplier_details sd ON n.n_nationkey = sd.s_nationkey
LEFT JOIN high_value_customers hvc ON n.n_nationkey = hvc.c_nationkey
LEFT JOIN lineitem_summary ls ON hvc.c_custkey = (
    SELECT o.o_custkey 
    FROM orders o 
    WHERE o.o_orderkey = ls.l_orderkey
    LIMIT 1
)
GROUP BY n.n_name, sd.s_name, hvc.c_name
ORDER BY n.n_name, total_sales DESC, sd.total_supply_cost DESC;
