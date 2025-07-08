
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS lineitem_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey 
    WHERE 
        o.o_totalprice > (
            SELECT AVG(o2.o_totalprice) 
            FROM orders o2 
            WHERE o2.o_orderstatus = 'O'
        )
    GROUP BY 
        o.o_orderkey, o.o_totalprice
),
SupplierPartCounts AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        partsupp ps 
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    spc.supplier_count,
    CASE 
        WHEN r.rank IS NOT NULL THEN r.s_name
        ELSE 'No Supplier'
    END AS top_supplier,
    hvo.o_orderkey,
    hvo.o_totalprice,
    hvo.lineitem_count
FROM 
    part p
LEFT JOIN 
    SupplierPartCounts spc ON p.p_partkey = spc.ps_partkey
LEFT JOIN 
    RankedSuppliers r ON r.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = p.p_partkey 
        ORDER BY ps.ps_supplycost ASC 
        LIMIT 1
    )
LEFT JOIN 
    HighValueOrders hvo ON hvo.o_orderkey = (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey 
        ORDER BY l.l_extendedprice DESC 
        LIMIT 1
    )
WHERE 
    (spc.supplier_count IS NULL OR spc.supplier_count > 0) 
    AND (hvo.lineitem_count > 1 OR hvo.lineitem_count IS NULL)
ORDER BY 
    p.p_partkey, 
    hvo.o_totalprice DESC;
