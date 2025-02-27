WITH RECURSIVE SupplyChain AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) AS total_availqty, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_availqty) > 0
    
    UNION ALL
    
    SELECT 
        ps.ps_partkey, 
        S.total_availqty + ps.ps_availqty, 
        S.total_supplycost + (ps.ps_supplycost * ps.ps_availqty)
    FROM 
        SupplyChain S
    JOIN 
        partsupp ps ON S.ps_partkey = ps.ps_partkey
    WHERE 
        ps.ps_availqty > 0
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
    HAVING 
        COUNT(ps.ps_partkey) > 5
)
SELECT 
    r.r_name, 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS num_customers,
    AVG(co.total_spent) AS avg_spent,
    SUM(sc.total_availqty) AS total_avail_qty,
    SUM(sc.total_supplycost) AS total_supply_cost,
    COUNT(DISTINCT rs.s_suppkey) AS num_suppliers
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    CustomerOrders co ON c.c_custkey = co.c_custkey
LEFT JOIN 
    SupplyChain sc ON sc.ps_partkey IN (SELECT ps_partkey FROM partsupp)
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey IN (SELECT ps_suppkey FROM partsupp)
WHERE 
    co.total_spent IS NOT NULL
GROUP BY 
    r.r_name, n.n_name
HAVING 
    AVG(co.total_spent) > 1000
ORDER BY 
    r.r_name, n.n_name;
