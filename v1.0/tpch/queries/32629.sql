
WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_acctbal
    FROM supplier s
    INNER JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
),
part_availability AS (
    SELECT p.p_partkey, p.p_brand, SUM(ps.ps_availqty) AS total_available
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_brand
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
latest_order_date AS (
    SELECT o.o_orderkey, MAX(o.o_orderdate) AS latest_date
    FROM orders o
    GROUP BY o.o_orderkey
),
lineitem_stats AS (
    SELECT
        l.l_orderkey,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS average_price,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM lineitem l
    WHERE l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY l.l_orderkey
)
SELECT 
    cs.c_name,
    COALESCE(ps.total_available, 0) AS total_available_parts,
    COALESCE(cs.order_count, 0) AS order_count,
    COALESCE(cs.total_spent, 0) AS total_spent,
    lh.latest_date,
    AVG(ls.average_price) AS avg_extended_price,
    SUM(ls.unique_parts) AS total_unique_parts
FROM customer_order_summary cs
FULL OUTER JOIN part_availability ps ON cs.c_custkey = ps.p_partkey
FULL OUTER JOIN latest_order_date lh ON cs.order_count = lh.o_orderkey
LEFT JOIN lineitem_stats ls ON cs.order_count = ls.l_orderkey
WHERE cs.total_spent IS NOT NULL OR (ps.total_available > 0)
GROUP BY cs.c_name, ps.total_available, cs.order_count, cs.total_spent, lh.latest_date
HAVING SUM(ls.unique_parts) > 5
ORDER BY cs.total_spent DESC, total_available_parts DESC;
