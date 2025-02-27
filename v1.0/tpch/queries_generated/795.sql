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
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        COUNT(*) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_suppkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rn <= 5
    GROUP BY 
        r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey
),
FinalReport AS (
    SELECT 
        t.r_name,
        t.supplier_count,
        t.total_acctbal,
        co.c_custkey,
        co.order_count,
        co.total_spent
    FROM 
        TopSuppliers t
    FULL OUTER JOIN 
        CustomerOrders co ON t.supplier_count = co.order_count
)
SELECT
    f.r_name,
    COALESCE(f.supplier_count, 0) AS supplier_count,
    COALESCE(f.total_acctbal, 0.00) AS total_supplier_acctbal,
    f.c_custkey,
    COALESCE(f.order_count, 0) AS order_count,
    COALESCE(f.total_spent, 0.00) AS total_customer_spent
FROM 
    FinalReport f
WHERE 
    (f.supplier_count > 0 OR f.order_count > 0)
ORDER BY 
    f.r_name, f.total_spent DESC;
