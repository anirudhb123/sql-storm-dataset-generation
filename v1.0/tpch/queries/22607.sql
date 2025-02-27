
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
OrderStatistics AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_custkey
),
PartSupplierCounts AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_name,
    p.p_mfgr,
    CASE 
        WHEN ps.supplier_count > 5 THEN 'Highly Supplied' 
        ELSE 'Low Supply' 
    END AS supply_category,
    os.order_count,
    os.total_spent,
    rs.s_name AS top_supplier_name,
    COALESCE(rs.s_acctbal, 0) AS supplier_balance
FROM 
    part p
LEFT JOIN 
    PartSupplierCounts ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    OrderStatistics os ON os.o_custkey = (
        SELECT 
            c.c_custkey 
        FROM 
            customer c 
        WHERE 
            c.c_acctbal = (SELECT MAX(c2.c_acctbal) FROM customer c2)
        LIMIT 1
    )
LEFT JOIN 
    RankedSuppliers rs ON rs.rn = 1 AND rs.s_suppkey IN (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_partkey = p.p_partkey
    )
WHERE 
    p.p_size > 10 
    AND p.p_retailprice IS NOT NULL 
    AND EXISTS (
        SELECT 1 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey 
            AND (l.l_discount > 0.1 OR l.l_tax BETWEEN 0.05 AND 0.15)
    )
ORDER BY 
    p.p_retailprice DESC, 
    os.total_spent DESC;
