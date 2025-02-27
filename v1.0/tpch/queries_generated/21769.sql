WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank,
        COUNT(*) OVER (PARTITION BY p.p_brand) AS total_parts
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'Unknown' 
            ELSE 'Known' 
        END AS acct_status
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000 OR s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_comment LIKE '%Top%')
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderstatus,
        CASE 
            WHEN l.l_returnflag = 'Y' THEN 'Returned' 
            ELSE 'Completed' 
        END AS order_status,
        SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY o.o_orderkey) AS adjusted_price
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
),
SupplierPerformance AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * p.p_size) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers,
        p.p_brand
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, p.p_brand
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_mfgr,
    COALESCE(sp.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(sp.unique_suppliers, 0) AS unique_suppliers,
    od.order_status,
    od.adjusted_price
FROM 
    RankedParts rp
LEFT JOIN 
    SupplierPerformance sp ON rp.p_partkey = sp.ps_partkey
LEFT JOIN 
    OrderDetails od ON rp.p_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O' LIMIT 1))
WHERE 
    rp.brand_rank <= 3 AND 
    (sp.unique_suppliers > 1 OR sp.total_supply_cost IS NULL)
ORDER BY 
    rp.p_brand, total_supply_cost DESC;
