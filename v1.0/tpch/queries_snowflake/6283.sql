WITH SupplierCost AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_brand, 
        p.p_name, 
        SUM(l.l_quantity) AS total_quantity
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_brand, p.p_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        sc.total_cost
    FROM 
        supplier s
    JOIN 
        SupplierCost sc ON s.s_suppkey = sc.s_suppkey
    ORDER BY 
        sc.total_cost DESC
    LIMIT 10
),
HighSellingParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        pd.total_quantity
    FROM 
        PartDetails pd
    JOIN 
        part p ON pd.p_partkey = p.p_partkey
    WHERE 
        pd.total_quantity > (
            SELECT AVG(total_quantity) FROM PartDetails
        )
)
SELECT 
    ts.s_name, 
    ts.total_cost, 
    hsp.p_name, 
    hsp.total_quantity
FROM 
    TopSuppliers ts
JOIN 
    HighSellingParts hsp ON hsp.p_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_suppkey = ts.s_suppkey
    )
ORDER BY 
    ts.total_cost DESC, hsp.total_quantity DESC;
