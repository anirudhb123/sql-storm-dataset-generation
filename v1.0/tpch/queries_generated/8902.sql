WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 10000
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 50000
),
HighValueItems AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '2023-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(l.l_extendedprice) > 100000
)
SELECT 
    ns.n_name AS nation_name,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
    COUNT(DISTINCT tc.c_custkey) AS customer_count,
    COUNT(DISTINCT hvi.p_partkey) AS high_value_item_count
FROM 
    RankedSuppliers rs
JOIN 
    nation ns ON rs.s_nationkey = ns.n_nationkey
JOIN 
    TopCustomers tc ON rs.s_nationkey = tc.c_nationkey
JOIN 
    HighValueItems hvi ON hvi.total_revenue > 100000
GROUP BY 
    ns.n_name
ORDER BY 
    supplier_count DESC, customer_count DESC, high_value_item_count DESC;
