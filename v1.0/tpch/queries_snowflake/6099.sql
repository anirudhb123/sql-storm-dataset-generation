WITH RankedSuppliers AS (
    SELECT 
        s_name,
        s_acctbal,
        n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_name,
        rs.s_acctbal,
        rs.nation_name
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 5
),
OrderSummary AS (
    SELECT 
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
),
SupplierProductStats AS (
    SELECT 
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_name
)
SELECT 
    os.c_name,
    os.total_spent,
    os.order_count,
    t.s_name AS top_supplier,
    t.s_acctbal AS supplier_balance,
    ps.p_name AS product_name,
    ps.total_available,
    ps.total_value
FROM 
    OrderSummary os
JOIN 
    TopSuppliers t ON os.total_spent > t.s_acctbal
JOIN 
    SupplierProductStats ps ON t.s_name LIKE CONCAT('%', ps.p_name, '%')
WHERE 
    os.order_count > 10
ORDER BY 
    os.total_spent DESC, 
    t.s_acctbal DESC;
