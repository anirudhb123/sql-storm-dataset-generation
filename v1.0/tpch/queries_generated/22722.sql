WITH RECURSIVE HighPriceParts AS (
    SELECT 
        p_partkey, 
        p_name, 
        p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p_type ORDER BY p_retailprice DESC) AS rn
    FROM 
        part
    WHERE 
        p_retailprice IS NOT NULL
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
)
SELECT 
    hpp.p_partkey,
    hpp.p_name,
    hpp.p_retailprice,
    COALESCE(si.total_avail_qty, 0) AS total_avail_qty,
    CASE 
        WHEN hpp.rn = 1 THEN 'Highest Price' 
        ELSE 'Other Price'
    END AS price_category,
    CASE 
        WHEN si.total_avail_qty IS NULL THEN 'No Supplier'
        ELSE 'Supplied'
    END AS supplier_status,
    COUNT(DISTINCT o.o_orderkey) OVER (PARTITION BY hpp.p_partkey) AS order_count
FROM 
    HighPriceParts hpp
LEFT JOIN 
    SupplierInfo si ON hpp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = si.s_suppkey)
LEFT JOIN 
    lineitem l ON hpp.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    hpp.rn <= 3
AND 
    (hpp.p_retailprice / NULLIF(si.total_supply_cost, 0) > 1.5 OR si.total_avail_qty IS NULL)
HAVING 
    SUM(l.l_quantity) > 0
ORDER BY 
    hpp.p_partkey, supplier_status DESC, price_category;
