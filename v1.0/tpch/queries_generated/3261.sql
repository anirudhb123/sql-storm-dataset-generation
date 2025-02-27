WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_supplycost DESC) AS rank
    FROM 
        SupplierSummary
)
SELECT 
    p.p_name,
    p.p_mfgr,
    p.p_retailprice,
    COALESCE(ts.total_available_quantity, 0) AS supplier_qty,
    COALESCE(ts.total_supplycost, 0) AS supplier_cost,
    CASE 
        WHEN ts.rank <= 10 THEN 'Top Supplier'
        ELSE 'Other Supplier'
    END AS supplier_category
FROM 
    part p
LEFT JOIN 
    TopSuppliers ts ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ts.s_suppkey)
WHERE 
    p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) 
        FROM part p2 
        WHERE p2.p_size < p.p_size
    )
OR 
    p.p_size BETWEEN 8 AND 20
ORDER BY 
    supplier_qty DESC NULLS LAST, p.p_name;
