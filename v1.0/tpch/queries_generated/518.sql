WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(month, -6, GETDATE()) 
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
PartRegions AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        r.r_name AS region_name, 
        p.p_retailprice,
        COALESCE(NULLIF(sd.total_supply_cost, 0), NULL) AS supplier_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        SupplierDetails sd ON s.s_suppkey = sd.s_suppkey
)
SELECT 
    pr.region_name,
    COUNT(DISTINCT pr.p_partkey) AS total_parts,
    AVG(pr.p_retailprice) AS avg_retail_price,
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) AS total_completed_sales,
    SUM(CASE WHEN o.o_orderstatus = 'O' THEN 1 ELSE 0 END) AS open_orders_count,
    STRING_AGG(DISTINCT s.s_name, ', ') AS unique_suppliers
FROM 
    PartRegions pr
LEFT JOIN 
    RankedOrders o ON pr.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')))
LEFT JOIN 
    supplier s ON pr.supplier_cost IS NOT NULL AND s.s_suppkey = pr.supplier_cost
GROUP BY 
    pr.region_name
ORDER BY 
    total_parts DESC, avg_retail_price ASC;
