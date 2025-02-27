
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn,
        n.n_nationkey
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_regionkey,
        r.r_name, 
        COUNT(rs.s_suppkey) AS supplier_count,
        SUM(rs.s_acctbal) AS total_acctbal
    FROM 
        region r
    LEFT JOIN 
        RankedSuppliers rs ON rs.n_nationkey IN (
            SELECT n.n_nationkey 
            FROM nation n 
            WHERE n.n_regionkey = r.r_regionkey
        ) AND rs.rn <= 5
    GROUP BY 
        r.r_regionkey, r.r_name
),
AverageOrderValues AS (
    SELECT 
        c.c_nationkey,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
)
SELECT 
    r.r_name,
    COALESCE(ts.supplier_count, 0) AS supplier_count,
    COALESCE(ts.total_acctbal, 0) AS total_acctbal,
    a.avg_order_value
FROM 
    region r
LEFT JOIN 
    TopSuppliers ts ON r.r_regionkey = ts.r_regionkey
LEFT JOIN 
    AverageOrderValues a ON a.c_nationkey IN (
        SELECT n.n_nationkey 
        FROM nation n 
        WHERE n.n_regionkey = r.r_regionkey
    )
WHERE 
    r.r_comment IS NOT NULL
ORDER BY 
    r.r_name;
