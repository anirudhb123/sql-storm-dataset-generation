WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
TopSuppliers AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        r.r_name AS region_name,
        rs.s_name,
        rs.s_acctbal
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.supplier_rank = 1
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 1000
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ts.p_partkey,
    ts.p_name,
    ts.region_name,
    ts.s_name AS top_supplier,
    COALESCE(co.total_spent, 0) AS customer_total_spent,
    COALESCE(co.order_count, 0) AS customer_order_count,
    CASE 
        WHEN co.order_count IS NULL THEN 'No Orders' 
        ELSE 'Has Orders' 
    END AS order_status
FROM 
    TopSuppliers ts
LEFT JOIN 
    CustomerOrders co ON ts.s_name = co.c_name
WHERE 
    ts.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
ORDER BY 
    ts.p_partkey, customer_total_spent DESC;
