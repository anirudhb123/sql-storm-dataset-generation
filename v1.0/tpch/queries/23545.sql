WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_availqty * ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    INNER JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    INNER JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
RegionDetails AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
SupplierSummary AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_supply_value,
        rd.total_sales,
        CASE 
            WHEN rd.total_sales > 0 THEN ROUND((rs.total_supply_value / rd.total_sales) * 100, 2)
            ELSE NULL 
        END AS percentage_of_sales
    FROM 
        RankedSuppliers rs
    FULL OUTER JOIN 
        RegionDetails rd ON rs.rank = 1
)
SELECT 
    s.s_name,
    ROUND(SUM(l.l_extendedprice * (1 - l.l_discount)), 2) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(CASE WHEN l.l_quantity IS NULL THEN NULL ELSE l.l_quantity END) AS avg_quantity,
    STRING_AGG(DISTINCT CASE WHEN c.c_mktsegment IS NULL THEN 'Unspecified' ELSE c.c_mktsegment END, ', ') AS market_segments
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    RegionDetails rd ON rd.total_sales > 0
WHERE 
    s.s_acctbal IS NOT NULL AND s.s_acctbal != 0
GROUP BY 
    s.s_name
ORDER BY 
    total_revenue DESC 
LIMIT 10;
