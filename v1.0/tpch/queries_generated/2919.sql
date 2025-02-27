WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
), 
PartStats AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_availqty) AS total_available, 
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name, 
    ps.p_name, 
    COALESCE(cs.c_name, 'No Customers') AS customer_name, 
    SUM(COALESCE(cs.total_spent, 0)) AS total_spent, 
    COUNT(DISTINCT rs.s_suppkey) AS unique_suppliers,
    p.total_available,
    p.avg_supply_cost
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey AND rs.rank <= 3
LEFT JOIN 
    PartStats p ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey LIMIT 1)
LEFT JOIN 
    CustomerOrders cs ON cs.total_spent > 1000
WHERE 
    r.r_name LIKE 'S%' 
GROUP BY 
    r.r_name, ps.p_name, cs.c_name
HAVING 
    SUM(p.total_available) > 50
ORDER BY 
    r.r_name, total_spent DESC;
