WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT ps_abvsize
                     FROM partsupp ps
                     WHERE ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp))
),
supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        SUM(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_discounted_sales
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON l.l_partkey = ps.ps_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
potential_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        c.c_mktsegment,
        NTILE(5) OVER (ORDER BY c.c_acctbal DESC) AS segment_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL AND
        c.c_mktsegment IN ('1-2', '3-4')
),
filtered_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finalized'
            WHEN o.o_orderstatus IS NULL THEN 'Pending'
            ELSE 'Unknown'
        END AS order_status,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate < CURRENT_DATE - INTERVAL '1' YEAR
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderstatus
),
sales_summary AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        part p ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate > CURRENT_DATE - INTERVAL '3' MONTH
    GROUP BY 
        p.p_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    si.s_name AS supplier_name,
    cs.c_name AS customer_name,
    cs.c_acctbal AS customer_balance,
    ps.total_discounted_sales AS supplier_discounted_sales,
    ss.total_sales AS part_sales,
    fo.line_count AS order_lines,
    CASE 
        WHEN ss.order_count >= 10 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS sales_volume
FROM 
    ranked_parts p
LEFT JOIN 
    supplier_info si ON si.s_suppkey = (SELECT ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey LIMIT 1)
LEFT JOIN 
    potential_customers cs ON cs.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = (SELECT MIN(o2.o_orderkey) FROM orders o2 WHERE o2.o_orderkey = p.p_partkey) LIMIT 1)
LEFT JOIN 
    sales_summary ss ON ss.p_partkey = p.p_partkey
LEFT JOIN 
    filtered_orders fo ON fo.o_orderkey = (SELECT MIN(o.o_orderkey) FROM orders o WHERE o.o_orderkey = p.p_partkey)
WHERE 
    p.brand_rank <= 3
ORDER BY 
    p.p_retailprice DESC, si.total_discounted_sales DESC NULLS LAST;
