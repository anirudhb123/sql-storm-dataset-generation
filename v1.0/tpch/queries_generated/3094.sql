WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
RegionNation AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    rs.r_name,
    COUNT(DISTINCT cs.c_custkey) AS number_of_customers,
    SUM(ss.total_available_quantity) AS total_available_parts,
    AVG(ss.avg_supply_cost) AS average_supply_cost,
    MAX(cs.total_spent) AS highest_spending_customer,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity
FROM 
    RegionNation rs
LEFT JOIN 
    CustomerOrderStats cs ON rs.n_nationkey = cs.c_custkey
LEFT JOIN 
    SupplierStats ss ON rs.n_nationkey = ss.s_suppkey
LEFT JOIN 
    lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey)
GROUP BY 
    rs.r_name
ORDER BY 
    total_available_parts DESC, highest_spending_customer DESC;
