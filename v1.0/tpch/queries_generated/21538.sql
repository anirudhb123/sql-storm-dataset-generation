WITH CTE_Supplier_Summary AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS total_parts,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CTE_Customer_Orders AS (
    SELECT o.o_orderkey,
           o.o_custkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_order_value,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY o.o_orderkey, o.o_custkey, c.c_nationkey
)
SELECT r.r_name,
       cs.total_supply_cost,
       coalesce(cust_order_count.total, 0) AS order_count,
       (SELECT COUNT(DISTINCT c.c_custkey)
        FROM customer c
        WHERE c.c_nationkey = n.n_nationkey) AS total_customers_in_region
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN CTE_Supplier_Summary cs ON n.n_nationkey = cs.s_nationkey
LEFT JOIN (
    SELECT o.o_custkey,
           COUNT(o.o_orderkey) AS total
    FROM orders o
    GROUP BY o.o_custkey
) AS cust_order_count ON cust_order_count.o_custkey = cs.s_suppkey
WHERE (cs.total_supply_cost IS NOT NULL OR cust_order_count.total > 0)
  AND r.r_name LIKE 'N%'
ORDER BY r.r_name, cs.total_supply_cost DESC
FETCH FIRST 10 ROWS ONLY;
