WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
), SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_value,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_tax > (SELECT AVG(l_tax) FROM lineitem)
    GROUP BY 
        o.o_orderkey
)

SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_retailprice,
    (SELECT COUNT(*) FROM SupplierStats s WHERE s.total_value > 10000) AS high_value_suppliers,
    CASE 
        WHEN (SELECT AVG(s.s_acctbal) FROM SupplierStats s) IS NULL THEN 'No Supplier'
        ELSE (SELECT AVG(s.s_acctbal) FROM SupplierStats s)::VARCHAR
    END AS average_supplier_balance,
    od.revenue,
    od.item_count
FROM 
    RankedParts rp
LEFT JOIN 
    OrderDetails od ON rp.p_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_linenumber = 1 AND l.l_orderkey = od.o_orderkey)
WHERE 
    rp.rn <= 5
    AND rp.p_retailprice > (SELECT MAX(p2.p_retailprice) FROM part p2 WHERE p2.p_type LIKE 'small%')
    OR rp.p_name LIKE '%fragile%'
ORDER BY 
    rp.p_partkey
OFFSET 10 LIMIT 50;
