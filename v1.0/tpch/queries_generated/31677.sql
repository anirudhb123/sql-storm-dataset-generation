WITH RECURSIVE supplier_analysis AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        region.r_name,
        nation.n_name,
        ROW_NUMBER() OVER(PARTITION BY region.r_regionkey ORDER BY s.s_acctbal DESC) as rn
    FROM 
        supplier s
    JOIN 
        nation ON s.s_nationkey = nation.n_nationkey
    JOIN 
        region ON nation.n_regionkey = region.r_regionkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 100000
),
top_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        r.r_name
    FROM 
        supplier_analysis s
    WHERE 
        s.rn <= 3
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderdate,
        COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    ts.s_name,
    ts.s_acctbal,
    os.total_revenue,
    os.unique_customers,
    os.o_orderdate
FROM 
    top_suppliers ts
LEFT JOIN 
    order_summary os ON ts.s_suppkey = os.o_orderkey
WHERE 
    os.total_revenue > 50000
ORDER BY 
    os.total_revenue DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY
UNION
SELECT 
    'Average Supplier' AS supplier_name,
    AVG(s.s_acctbal) AS avg_acctbal,
    NULL AS total_revenue,
    NULL AS unique_customers,
    NULL AS order_date
FROM 
    supplier s
WHERE 
    s.s_acctbal IS NOT NULL
HAVING 
    COUNT(s.s_suppkey) > 0;
