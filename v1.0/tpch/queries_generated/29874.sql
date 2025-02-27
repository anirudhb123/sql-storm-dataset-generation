WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(DISTINCT o.o_orderkey) AS total_orders, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopProductSuppliers AS (
    SELECT 
        p.p_name, 
        array_agg(s.s_name ORDER BY s.s_acctbal DESC) AS top_suppliers
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_name
)
SELECT 
    cu.c_name AS customer_name, 
    cu.total_orders, 
    cu.total_spent, 
    ps.p_name AS product_name, 
    rs.s_name AS top_supplier
FROM 
    CustomerOrderSummary cu
JOIN 
    lineitem l ON cu.c_custkey = l.l_orderkey
JOIN 
    TopProductSuppliers ps ON l.l_partkey = ps.p_name
JOIN 
    RankedSuppliers rs ON ps.p_name = p.p_name AND rs.rank <= 5
WHERE 
    cu.total_orders > 10
ORDER BY 
    cu.total_spent DESC, rs.s_acctbal DESC;
