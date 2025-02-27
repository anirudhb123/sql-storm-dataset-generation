WITH RECURSIVE nation_hierarchy AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, 0 AS hierarchy_level
    FROM nation n
    WHERE n.n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.hierarchy_level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
sales_summary AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_nationkey
),
high_value_customers AS (
    SELECT c.c_nationkey, c.c_name, s.total_sales
    FROM customer c
    JOIN sales_summary s ON c.c_custkey = s.c_custkey
    WHERE s.total_sales > (
        SELECT AVG(total_sales) FROM sales_summary
    )
),
supplier_parts AS (
    SELECT s.s_suppkey, s.s_acctbal, p.p_partkey, p.p_name, ps.ps_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
)
SELECT
    n.n_name AS nation_name,
    h.c_name AS customer_name,
    COALESCE(SUM(sp.ps_availqty), 0) AS total_available_qty,
    COUNT(DISTINCT sp.p_partkey) AS total_parts,
    AVG(sp.s_acctbal) AS avg_supplier_balance
FROM nation_hierarchy n
LEFT JOIN high_value_customers h ON n.n_nationkey = h.c_nationkey
LEFT JOIN supplier_parts sp ON sp.s_suppkey = (
    SELECT MIN(s_suppkey)
    FROM supplier_parts
    WHERE s_acctbal > (
        SELECT AVG(s_acctbal)
        FROM supplier
    )
)
WHERE n.hierarchy_level < 2
GROUP BY n.n_name, h.c_name
ORDER BY total_available_qty DESC, avg_supplier_balance DESC;
