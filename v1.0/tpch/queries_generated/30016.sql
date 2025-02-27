WITH RECURSIVE sales_hierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 0 AS level
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_acctbal, sh.level + 1
    FROM customer c
    JOIN sales_hierarchy sh ON c.c_custkey = sh.c_custkey
    WHERE c.c_acctbal < sh.c_acctbal
),
monthly_sales AS (
    SELECT 
        o.o_orderkey,
        DATE_TRUNC('month', o.o_orderdate) AS order_month,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_income
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, order_month
),
top_part_supp AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 1000
),
supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS high_value_customers,
    COALESCE(SUM(ms.total_income), 0) AS total_monthly_income,
    COUNT(DISTINCT t.ps_partkey) AS active_parts,
    AVG(si.total_supplycost) AS avg_supplier_cost
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN monthly_sales ms ON c.c_custkey = ms.o_orderkey
LEFT JOIN top_part_supp t ON t.ps_partkey IN (SELECT p.p_partkey FROM part p)
LEFT JOIN supplier_info si ON si.s_suppkey = t.ps_suppkey
WHERE c.c_acctbal IS NOT NULL 
AND (c.c_mktsegment = 'BUILDING' OR c.c_mktsegment IS NULL)
GROUP BY r.r_name
HAVING AVG(si.total_supplycost) IS NOT NULL
ORDER BY r.r_name;
