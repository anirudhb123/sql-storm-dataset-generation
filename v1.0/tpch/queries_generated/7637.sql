WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        n.n_name AS nation, 
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY rs.total_cost DESC) AS rank
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 5 AND SUM(o.o_totalprice) > 10000
)
SELECT 
    ts.s_name AS supplier_name,
    f.customer_name,
    f.order_count,
    f.total_spent,
    r.r_name AS region_name
FROM 
    TopSuppliers ts
JOIN 
    nation n ON ts.n_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    FilteredCustomers f ON f.c_custkey IN (
        SELECT 
            o.o_custkey 
        FROM 
            orders o
        JOIN 
            lineitem l ON o.o_orderkey = l.l_orderkey
        WHERE 
            l.l_partkey IN (
                SELECT 
                    ps.ps_partkey 
                FROM 
                    partsupp ps
                WHERE 
                    ps.ps_suppkey = ts.s_suppkey
            )
    )
WHERE 
    ts.rank <= 3
ORDER BY 
    r.r_name, f.total_spent DESC;
