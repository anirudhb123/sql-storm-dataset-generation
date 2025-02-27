WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name
    FROM 
        RankedSuppliers s
    WHERE 
        total_supply_cost > (SELECT AVG(total_supply_cost) FROM RankedSuppliers)
),
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    ORDER BY 
        order_count DESC 
    LIMIT 10
)
SELECT 
    r.r_name AS region_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    SUM(o.o_totalprice) AS total_revenue, 
    AVG(c.c_acctbal) AS average_customer_balance
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    orders o ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 20))
JOIN 
    TopCustomers c ON o.o_custkey = c.c_custkey
WHERE 
    s.s_suppkey IN (SELECT s.s_suppkey FROM HighValueSuppliers s)
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC;
