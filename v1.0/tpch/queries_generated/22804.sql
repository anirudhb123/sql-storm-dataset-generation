WITH RECURSIVE ranked_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name IN ('CANADA', 'FRANCE')
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > (SELECT AVG(o2.o_totalprice)
                                    FROM orders o2 
                                    WHERE o2.o_orderdate < CURRENT_DATE - INTERVAL '1 year')
),
large_parts AS (
    SELECT p.p_partkey, p.p_name, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING AVG(ps.ps_supplycost) > (SELECT MAX(ps2.ps_supplycost)
                                     FROM partsupp ps2 WHERE ps2.ps_availqty > 100)
),
valid_lineitems AS (
    SELECT l.*
    FROM lineitem l 
    WHERE l.l_discount < 0.1
    AND l.l_returnflag = 'N'
),
relevant_orders AS (
    SELECT o.o_orderkey, GROUP_CONCAT(DISTINCT l.l_partkey) AS partkeys
    FROM orders o
    JOIN valid_lineitems l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT r.n_name AS supplier_nation,
       COUNT(DISTINCT r.s_suppkey) AS num_suppliers,
       COALESCE(SUM(c.total_spent), 0) AS total_customer_spending,
       COUNT(DISTINCT l.l_orderkey) AS total_orders,
       CASE WHEN COUNT(DISTINCT lp.p_partkey) > 10 THEN 'Diverse'
            ELSE 'Limited' END AS part_diversity,
       CASE WHEN r.rank <= 3 THEN 'Top Supplier' ELSE 'Other' END AS supplier_rank
FROM ranked_suppliers r
LEFT JOIN customer_orders c ON r.s_suppkey = c.c_custkey
LEFT JOIN relevant_orders lo ON lo.o_orderkey = r.s_suppkey
LEFT JOIN large_parts lp ON lp.p_partkey IN (SELECT partkey FROM unnest(lo.partkeys))
GROUP BY r.n_name, r.rank
ORDER BY num_suppliers DESC, total_customer_spending DESC
LIMIT 50;
