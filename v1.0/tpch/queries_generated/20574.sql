WITH RankedParts AS (
    SELECT 
        p_partkey,
        p_name,
        p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p_mfgr ORDER BY p_retailprice DESC) AS rank
    FROM 
        part
),
SupplierSummary AS (
    SELECT 
        s_nationkey,
        COUNT(DISTINCT s_suppkey) AS supplier_count,
        SUM(s_acctbal) AS total_acctbal
    FROM 
        supplier
    GROUP BY 
        s_nationkey
),
HighValueOrders AS (
    SELECT 
        o_custkey,
        SUM(o_totalprice) AS total_spent
    FROM 
        orders
    WHERE 
        o_orderstatus = 'O' AND 
        o_orderdate >= DATEADD(YEAR, -1, CURRENT_DATE)
    GROUP BY 
        o_custkey
),
LineitemWithDiscounts AS (
    SELECT 
        l_orderkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_discount_price
    FROM 
        lineitem
    WHERE 
        l_returnflag = 'N'
    GROUP BY 
        l_orderkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(COALESCE(ls.total_discount_price, 0)) AS total_discounted_sales,
    AVG(ps.total_acctbal) AS avg_supplier_acctbal,
    MAX(pp.p_retailprice) AS max_product_price,
    MIN(CASE WHEN pp.rank = 1 THEN pp.p_retailprice ELSE NULL END) AS min_highest_price_per_mfgr,
    STRING_AGG(DISTINCT pp.p_name) AS top_products
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey 
JOIN 
    SupplierSummary ps ON ps.s_nationkey = n.n_nationkey 
JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    HighValueOrders ho ON ho.o_custkey = c.c_custkey
LEFT JOIN 
    LineitemWithDiscounts ls ON ls.l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = c.c_custkey)
JOIN 
    RankedParts pp ON pp.p_partkey = (SELECT TOP 1 ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost = (SELECT MIN(pss.ps_supplycost) FROM partsupp pss WHERE pss.ps_partkey = pp.p_partkey))
WHERE 
    r.r_name LIKE 'A%' AND 
    ps.supplier_count > 10
GROUP BY 
    r.r_name
HAVING 
    SUM(COALESCE(ls.total_discount_price, 0)) IS NOT NULL AND 
    MAX(pp.p_retailprice) > 50
ORDER BY 
    total_discounted_sales DESC, 
    customer_count ASC;
