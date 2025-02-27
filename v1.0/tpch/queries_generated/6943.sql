WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        r.r_name, 
        rs.s_name, 
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (
            SELECT s_nationkey FROM supplier WHERE s_suppkey = rs.s_suppkey)
        )
    WHERE 
        rs.rank <= 3
)
SELECT 
    t.r_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(o.o_totalprice) AS total_order_value,
    AVG(o.o_totalprice) AS average_order_value
FROM 
    TopSuppliers t
JOIN 
    orders o ON o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey IN (SELECT s_nationkey FROM supplier s WHERE s.s_name = t.s_name))
JOIN 
    customer c ON c.c_nationkey IN (SELECT n.n_nationkey FROM nation n JOIN supplier s ON n.n_nationkey = s.s_nationkey WHERE s.s_name = t.s_name)
GROUP BY 
    t.r_name
HAVING 
    SUM(o.o_totalprice) > 100000
ORDER BY 
    total_order_value DESC;
