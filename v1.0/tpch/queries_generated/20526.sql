WITH RECURSIVE qty_calculation AS (
    SELECT ps_partkey, ps_suppkey, ps_availqty, ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost DESC) AS rank
    FROM partsupp
    WHERE ps_availqty IS NOT NULL
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
filtered_suppliers AS (
    SELECT s.s_suppkey, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
line_item_summary AS (
    SELECT l.l_orderkey, COUNT(*) AS item_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM lineitem l
    GROUP BY l.l_orderkey
),
top_nations AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT c.c_custkey) AS cust_count
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING COUNT(DISTINCT c.c_custkey) > 10
),
ranked_part AS (
    SELECT p.p_partkey, p.p_name, COUNT(*) AS supplier_count,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty < 100
    GROUP BY p.p_partkey, p.p_name
    HAVING COUNT(*) >= 2
    ORDER BY avg_supply_cost DESC
    LIMIT 5
)
SELECT r.r_name, COALESCE(tc.total_value, 0) AS total_value,
       SUM(CASE WHEN n.cust_count IS NULL THEN 1 ELSE 0 END) AS null_customers
FROM region r
LEFT JOIN (
    SELECT rn.n_nationkey, SUM(lis.total_value) AS total_value
    FROM top_nations rn
    JOIN line_item_summary lis ON rn.n_nationkey = (
        SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE CONCAT('%',rn.n_name,'%')
    )
    GROUP BY rn.n_nationkey
) tc ON r.r_regionkey = (
    SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = tc.n_nationkey
)
LEFT JOIN top_nations n ON r.r_regionkey = (
    SELECT nt.n_regionkey FROM nation nt WHERE nt.n_nationkey = n.n_nationkey
)
GROUP BY r.r_name
ORDER BY total_value DESC, r.r_name
OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;
