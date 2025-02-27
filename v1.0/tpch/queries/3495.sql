
WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name,
        RANK() OVER(PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PartPrice AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
TopParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice,
        pp.total_supplycost,
        pp.supplier_count,
        ROW_NUMBER() OVER(ORDER BY p.p_retailprice DESC) AS rank_price
    FROM 
        part p
    LEFT JOIN 
        PartPrice pp ON p.p_partkey = pp.ps_partkey
)
SELECT 
    tp.p_name,
    COALESCE(tp.total_supplycost, 0) AS total_supplycost,
    COALESCE(su.s_name, 'No Supplier') AS primary_supplier,
    tp.supplier_count,
    CASE 
        WHEN tp.rank_price <= 5 THEN 'Top Part'
        ELSE 'Regular Part'
    END AS part_category
FROM 
    TopParts tp
LEFT JOIN 
    SupplierInfo su ON su.rank_acctbal = 1 AND su.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = tp.p_partkey
    )
WHERE 
    tp.total_supplycost IS NOT NULL OR tp.supplier_count > 0
ORDER BY 
    tp.rank_price;
