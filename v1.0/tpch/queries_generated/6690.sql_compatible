
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank,
        n.n_nationkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey, n.n_name
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        SUM(rs.total_supply_cost) AS total_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.n_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 5
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name,
    r.total_cost,
    AVG(c.c_acctbal) AS average_customer_balance,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    TopSuppliers r
LEFT JOIN 
    customer c ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = r.r_name)
LEFT JOIN 
    orders o ON o.o_custkey = c.c_custkey
GROUP BY 
    r.r_name, r.total_cost
ORDER BY 
    r.total_cost DESC;
