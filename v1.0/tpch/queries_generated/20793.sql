WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        MIN(ps.ps_supplycost) AS min_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        r.r_regionkey
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    p.p_name,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    CASE 
        WHEN SUM(COALESCE(l.l_tax, 0)) > 1000 THEN 'High Tax'
        ELSE 'Low Tax'
    END AS tax_status
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    RankedOrders o ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierCost sc ON p.p_partkey = sc.ps_partkey
LEFT JOIN 
    CustomerRegion cr ON cr.c_custkey = o.o_custkey
WHERE 
    p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_brand LIKE '%Bizarre%' AND p_retailprice < 50.00)
    AND (o.o_orderstatus = 'F' OR o.o_orderstatus IS NULL)
GROUP BY 
    p.p_name
HAVING 
    AVG(l.l_extendedprice * (1 - l.l_discount)) > 100
ORDER BY 
    avg_price_after_discount DESC;
