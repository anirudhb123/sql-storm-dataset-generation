
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND 
        o.o_orderdate < DATE '1997-01-01'
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_availability,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_mfgr,
        COALESCE(s.total_availability, 0) AS total_availability,
        COALESCE(ss.avg_supply_cost, 0) AS avg_supply_cost,
        CASE 
            WHEN p.p_retailprice IS NULL THEN 'No Price' 
            WHEN p.p_retailprice > 100 THEN 'Premium' 
            ELSE 'Standard' 
        END AS price_category
    FROM 
        part p
    LEFT JOIN 
        SupplierStats s ON p.p_partkey = s.ps_partkey
    LEFT JOIN 
        SupplierStats ss ON s.s_suppkey = ss.s_suppkey
),
FinalCalculations AS (
    SELECT 
        pd.p_partkey,
        pd.p_name,
        pd.price_category,
        roi.o_orderkey,
        roi.o_totalprice,
        pd.total_availability,
        pd.avg_supply_cost,
        CASE 
            WHEN pd.total_availability < 5 THEN 'Low Stock' 
            WHEN pd.total_availability BETWEEN 5 AND 20 THEN 'Medium Stock' 
            ELSE 'High Stock' 
        END AS stock_level
    FROM 
        PartDetails pd
    FULL OUTER JOIN 
        RankedOrders roi ON pd.p_partkey = roi.o_orderkey
)
SELECT 
    fc.p_partkey,
    fc.p_name,
    fc.price_category,
    fc.stock_level,
    COUNT(DISTINCT fc.o_orderkey) AS order_count,
    SUM(fc.o_totalprice) AS total_revenue,
    LISTAGG(DISTINCT CAST(fc.o_orderkey AS VARCHAR(255)), ',') AS order_keys
FROM 
    FinalCalculations fc
WHERE 
    fc.stock_level IS NOT NULL
GROUP BY 
    fc.p_partkey,
    fc.p_name,
    fc.price_category,
    fc.stock_level
HAVING 
    SUM(fc.o_totalprice) > 5000
ORDER BY 
    total_revenue DESC, 
    stock_level DESC;
