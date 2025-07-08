WITH RECURSIVE region_details AS (
    SELECT r.r_regionkey, r.r_name, r.r_comment, 
           1 AS depth
    FROM region r
    WHERE r.r_name LIKE 'E%'
    
    UNION ALL

    SELECT n.n_nationkey AS r_regionkey, n.n_name AS r_name, n.n_comment AS r_comment, 
           rd.depth + 1
    FROM nation n
    JOIN region_details rd ON n.n_regionkey = rd.r_regionkey
    WHERE rd.depth < 5
),
supplier_summary AS (
    SELECT s.s_nationkey, 
           SUM(s.s_acctbal) AS total_balance,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM supplier s
    GROUP BY s.s_nationkey
),
part_statistics AS (
    SELECT DISTINCT p.p_partkey, 
           p.p_name, 
           p.p_retailprice, 
           SUM(ps.ps_availqty) OVER (PARTITION BY p.p_partkey) AS total_available_qty
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
order_summary AS (
    SELECT o.o_orderkey, 
           o.o_orderstatus, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue_with_discount,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_discount BETWEEN 0.05 AND 0.3
    GROUP BY o.o_orderkey, o.o_orderstatus
)
SELECT rd.r_name, 
       ss.total_balance, 
       ps.total_available_qty, 
       os.total_revenue_with_discount
FROM region_details rd
FULL OUTER JOIN supplier_summary ss ON rd.r_regionkey = ss.s_nationkey
LEFT JOIN part_statistics ps ON ps.p_partkey = (SELECT MIN(p.p_partkey)
                                                  FROM part p
                                                  WHERE p.p_retailprice > 20.00 
                                                  AND p.p_name IS NOT NULL)
LEFT JOIN order_summary os ON os.o_orderkey = (SELECT MAX(o.o_orderkey)
                                                 FROM orders o
                                                 WHERE o.o_orderstatus = 'O'
                                                 AND o.o_totalprice IS NOT NULL)
WHERE ss.total_balance IS NOT NULL
  OR os.total_revenue_with_discount IS NOT NULL
ORDER BY rd.depth, ss.total_balance DESC NULLS LAST;
