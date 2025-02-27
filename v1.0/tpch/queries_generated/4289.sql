WITH TotalSales AS (
    SELECT 
        l.partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '1993-01-01' AND o.o_orderdate < '1994-01-01'
    GROUP BY 
        l.partkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name,
        COUNT(ps.ps_supplycost) AS supply_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
    HAVING 
        COUNT(ps.ps_supplycost) > 0
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(ts.total_revenue, 0) AS total_revenue,
    COALESCE(sd.supply_count, 0) AS supply_count,
    (CASE 
        WHEN COALESCE(ts.total_revenue, 0) > 1000 THEN 'High'
        WHEN COALESCE(ts.total_revenue, 0) BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low' 
    END) AS revenue_category,
    CONCAT('Manufacturer: ', p.p_mfgr, ' | Type: ', p.p_type) AS product_info
FROM 
    part p
LEFT JOIN 
    TotalSales ts ON p.p_partkey = ts.partkey
LEFT JOIN 
    SupplierDetails sd ON EXISTS (
        SELECT 1 
        FROM partsupp ps 
        WHERE ps.ps_partkey = p.p_partkey 
        AND ps.ps_suppkey = sd.s_suppkey
    )
WHERE 
    p.p_size IN (10, 20, 30)
ORDER BY 
    revenue_category DESC, total_revenue DESC;
