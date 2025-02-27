WITH RECURSIVE part_suppliers AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
    UNION ALL
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost
    FROM partsupp ps
    JOIN part_suppliers ps_rec ON ps.ps_partkey = ps_rec.ps_partkey
    WHERE ps.ps_supplycost < ps_rec.ps_supplycost
),
order_summary AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
customer_contributions AS (
    SELECT c.c_custkey, SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_contribution
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem lo ON o.o_orderkey = lo.l_orderkey
    GROUP BY c.c_custkey
)
SELECT n.n_name AS nation_name,
       SUM(ps.ps_availqty) AS total_available_quantity,
       COUNT(DISTINCT cs.c_custkey) AS customer_count,
       AVG(cs.total_contribution) AS avg_customer_contribution,
       MAX(os.o_totalprice) AS max_order_value,
       (CASE
            WHEN SUM(ps.ps_availqty) IS NULL THEN 'No Supplies'
            ELSE 'Supplies Available'
        END) AS supply_status
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN part_suppliers ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN customer_contributions cs ON cs.c_custkey = s.s_suppkey  -- Assuming supplier's key aligns with customer for demonstration purpose
LEFT JOIN order_summary os ON os.o_orderkey = s.s_suppkey  -- Assuming a logical condition for demonstration purpose
GROUP BY n.n_name
HAVING SUM(ps.ps_availqty) > 0
ORDER BY customer_count DESC, avg_customer_contribution DESC
LIMIT 10;
