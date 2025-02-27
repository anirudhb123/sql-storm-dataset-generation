WITH RECURSIVE SupplyChain AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS SupplyRank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > 0
    UNION ALL
    SELECT 
        sc.ps_partkey,
        sc.s_suppkey,
        sc.s_name,
        sc.ps_availqty + p.ps_availqty AS total_availqty,
        sc.ps_supplycost + p.ps_supplycost AS total_supplycost,
        RANK() OVER (PARTITION BY sc.ps_partkey ORDER BY sc.ps_supplycost + p.ps_supplycost ASC) AS SupplyRank
    FROM 
        SupplyChain sc
    JOIN 
        partsupp p ON sc.ps_partkey = p.ps_partkey
    WHERE 
        p.ps_availqty > 0 AND sc.s_suppkey != p.ps_suppkey
),
FilteredSupply AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        ps.ps_supplycost,
        COALESCE(NULLIF(s.s_acctbal, 0), NULL) AS valid_acctbal,
        CASE 
            WHEN s.s_acctbal < 500 THEN 'Low'
            WHEN s.s_acctbal BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'High'
        END AS acctbal_category
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty IS NOT NULL AND ps.ps_supplycost IS NOT NULL
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey 
    GROUP BY 
        o.o_orderkey
)
SELECT 
    fs.ps_partkey,
    fs.s_suppkey,
    fs.s_name,
    SUM(fs.valid_acctbal) AS total_acctbal,
    COUNT(DISTINCT fs.acctbal_category) AS unique_categories,
    COUNT(od.o_orderkey) AS orders_count,
    AVG(sc.ps_supplycost) AS avg_supplycost,
    MIN(od.total_revenue) AS min_revenue,
    MAX(od.total_revenue) AS max_revenue,
    CASE 
        WHEN SUM(od.total_revenue) > 10000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    FilteredSupply fs
LEFT JOIN 
    SupplyChain sc ON fs.ps_partkey = sc.ps_partkey
LEFT JOIN 
    OrderDetails od ON od.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderkey IS NOT NULL)
GROUP BY 
    fs.ps_partkey, fs.s_suppkey, fs.s_name
HAVING 
    SUM(fs.valid_acctbal) IS NOT NULL AND COUNT(od.o_orderkey) > 5
ORDER BY 
    total_acctbal DESC, orders_count ASC;
