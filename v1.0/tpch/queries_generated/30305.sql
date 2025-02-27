WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, CAST(s_name AS varchar(255)) AS hierarchy
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, CONCAT(sh.hierarchy, ' > ', s.s_name)
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal > sh.s_acctbal
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS num_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
part_supplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
ranked_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_mfgr, ps.total_supplycost,
           RANK() OVER (ORDER BY ps.total_supplycost DESC) AS part_rank
    FROM part p
    LEFT JOIN part_supplier ps ON p.p_partkey = ps.ps_partkey
)
SELECT c.c_name, coalesce(so.total_spent, 0) AS total_spent, 
       CASE WHEN r.part_rank IS NOT NULL THEN r.p_name ELSE 'No Supply' END AS popular_part_name,
       COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END), 0) AS returned_qty,
       COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM customer_orders co
LEFT JOIN customer c ON co.c_custkey = c.c_custkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
LEFT JOIN ranked_parts r ON l.l_partkey = r.p_partkey 
LEFT JOIN (SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent 
            FROM customer c 
            JOIN orders o ON c.c_custkey = o.o_custkey
            WHERE o.o_orderdate >= '2022-01-01'
            GROUP BY c.c_custkey) so ON c.c_custkey = so.c_custkey
WHERE c.c_acctbal IS NOT NULL 
GROUP BY c.c_name, so.total_spent, r.part_rank, r.p_name
HAVING coalesce(total_spent, 0) > 1000
ORDER BY total_spent DESC, c.c_name;
