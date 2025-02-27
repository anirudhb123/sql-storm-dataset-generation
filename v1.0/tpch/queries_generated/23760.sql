WITH RECURSIVE part_sales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        part p 
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
nation_info AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        nation n 
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
sales_rank AS (
    SELECT 
        ps.p_partkey,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        part_sales ps
    WHERE 
        total_sales IS NOT NULL
),
large_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        COUNT(DISTINCT l.l_orderkey) OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate) AS line_items_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_totalprice > 1000
)
SELECT 
    n.n_name,
    COALESCE(MAX(s.total_sales), 0) AS max_sales_per_nation,
    COUNT(DISTINCT lo.o_orderkey) AS large_orders_count,
    SUM(n.supplier_count) AS total_suppliers,
    SUM(n.total_acctbal) FILTER (WHERE n.n_name IS NOT NULL) AS total_acct_balances
FROM 
    nation_info n
LEFT JOIN 
    part_sales s ON n.n_nationkey IN (SELECT DISTINCT p.p_partkey FROM partsupp p)
LEFT JOIN 
    large_orders lo ON n.n_nationkey = (SELECT n.n_nationkey FROM supplier s JOIN nation n ON s.s_nationkey = n.n_nationkey WHERE s.s_suppkey = lo.o_orderkey)
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT lo.o_orderkey) >= 1 AND MAX(s.total_sales) > 0
ORDER BY 
    total_suppliers DESC, max_sales_per_nation DESC;
