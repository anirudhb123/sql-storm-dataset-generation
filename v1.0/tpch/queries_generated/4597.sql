WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
),

SupplierPartInfo AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_brand,
        p.p_retailprice
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 10
)

SELECT 
    r.r_name AS Region,
    SUM(CASE WHEN lo.l_returnflag = 'R' THEN lo.l_extendedprice ELSE 0 END) AS Total_Return_Amount,
    COUNT(DISTINCT c.c_custkey) AS Unique_Customers,
    AVG(lo.l_extendedprice * (1 - lo.l_discount)) AS Avg_Net_Sale,
    COUNT(DISTINCT o.o_orderkey) AS Total_Orders,
    COUNT(DISTINCT sp.s_suppkey) AS Suppliers_Selling_Products,
    MAX(sp.ps_supplycost) AS Max_Supply_Cost
FROM 
    RankedOrders o
LEFT JOIN 
    lineitem lo ON o.o_orderkey = lo.l_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    region r ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)
JOIN 
    SupplierPartInfo sp ON sp.ps_partkey = lo.l_partkey
WHERE 
    o.o_orderstatus IN ('O', 'F') AND
    lo.l_shipdate IS NOT NULL AND 
    (sp.p_brand LIKE 'Brand%')
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    Total_Return_Amount DESC NULLS LAST;
