WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_price, 
        p.p_mfgr, 
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rnk
    FROM 
        part p
), 
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_comment IS NOT NULL)
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount,
        COUNT(DISTINCT l.l_partkey) AS item_count,
        o.o_orderstatus
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
), 
SuppliersProducts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_name
    FROM 
        partsupp ps
    JOIN 
        RankedParts p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.rnk <= 5
)
SELECT 
    od.o_orderkey,
    SUM(sp.ps_supplycost) OVER (PARTITION BY od.o_orderkey) AS total_supplycost,
    COUNT(DISTINCT sp.ps_suppkey) AS total_suppliers,
    (CASE 
        WHEN od.total_amount IS NULL THEN 'No Order'
        ELSE 'Has Order'
     END) AS order_status,
    COALESCE(fp.s_name, 'Unknown Supplier') AS supplier_name
FROM 
    OrderDetails od
FULL OUTER JOIN 
    SuppliersProducts sp ON od.o_orderkey = sp.ps_partkey
LEFT JOIN 
    FilteredSuppliers fp ON sp.ps_suppkey = fp.s_suppkey
WHERE 
    (od.o_orderstatus = 'O' OR od.o_orderstatus IS NULL)
AND 
    (fp.s_acctbal IS NOT NULL OR sp.ps_availqty <= 10)
GROUP BY 
    od.o_orderkey,
    od.total_amount,
    fp.s_name
HAVING 
    COUNT(DISTINCT sp.ps_suppkey) > 0 OR MAX(od.item_count) > 3
ORDER BY 
    od.o_orderkey DESC;
