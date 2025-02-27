WITH RECURSIVE RegionSupplier AS (
    SELECT 
        r.r_name AS region_name, 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal 
    FROM 
        region r 
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey 
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey 
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
    UNION ALL
    SELECT 
        rs.region_name, 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal 
    FROM 
        RegionSupplier rs 
    JOIN 
        supplier s ON rs.s_suppkey IS NOT NULL AND s.s_suppkey <> rs.s_suppkey
    WHERE 
        s.s_acctbal < 100000.00
),
FrequentOrderSummary AS (
    SELECT 
        o.o_orderkey,
        COUNT(DISTINCT l.l_linenumber) OVER (PARTITION BY o.o_orderkey) AS total_lines,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        DENSE_RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    rs.region_name, 
    fs.o_orderkey, 
    fs.total_lines, 
    fs.net_revenue,
    CASE 
        WHEN fs.revenue_rank = 1 THEN 'Top Revenue'
        ELSE 'Regular Revenue'
    END AS revenue_category,
    STRING_AGG(DISTINCT CONCAT('Supplier: ', rs.s_name, ', Account Balance: ', rs.s_acctbal::varchar), '; ') AS suppliers_info
FROM 
    RegionSupplier rs 
LEFT JOIN 
    FrequentOrderSummary fs ON rs.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_retailprice IS NOT NULL AND p.p_retailprice >= 10.00
        )
    )
WHERE 
    rs.s_acctbal IS NOT NULL
GROUP BY 
    rs.region_name, fs.o_orderkey, fs.total_lines, fs.net_revenue, fs.revenue_rank
HAVING 
    COALESCE(SUM(fs.net_revenue), 0) > 5000.00 
ORDER BY 
    rs.region_name, fs.net_revenue DESC;
