WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS num_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT p.p_partkey) AS num_parts,
    COALESCE(cs.total_spent, 0) AS total_spent_by_customer,
    SUM(ss.total_avail_qty) AS sum_supply,
    AVG(ss.avg_supply_cost) AS avg_cost_supply,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    CustomerOrders cs ON cs.c_custkey = (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = n.n_nationkey
        ORDER BY c.c_acctbal DESC 
        LIMIT 1
    )
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey = s.s_suppkey
WHERE 
    p.p_retailprice BETWEEN 50 AND 500
    AND (p.p_size IS NULL OR p.p_size >= 10)
GROUP BY 
    n.n_name, 
    r.r_name, 
    cs.total_spent
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_spent_by_customer DESC, 
    num_parts DESC;
