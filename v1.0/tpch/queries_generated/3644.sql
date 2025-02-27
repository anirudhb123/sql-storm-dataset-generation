WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01'
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost ASC) as supplier_part_rank,
        CASE 
            WHEN ps.ps_supplycost < (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2) 
            THEN 'Below Average' 
            ELSE 'Above Average' 
        END as cost_comparison
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
FilteredCustomer AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    n.n_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(ps.ps_availqty) AS total_available_parts,
    AVG(spd.ps_supplycost) AS avg_supply_cost,
    fc.total_spent AS customer_spending
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    RankedOrders o ON o.o_orderkey IN (SELECT l.l_orderkey 
                                          FROM lineitem l 
                                          JOIN FilteredCustomer fc ON fc.c_custkey = (l.l_suppkey))  
LEFT JOIN 
    SupplierPartDetails spd ON spd.s_suppkey = s.s_suppkey
LEFT JOIN 
    FilteredCustomer fc ON fc.total_spent > 0
GROUP BY 
    r.r_name, n.n_name, fc.total_spent
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5 AND
    AVG(spd.ps_supplycost) < (SELECT AVG(ps.ps_supplycost) FROM partsupp ps)
ORDER BY 
    total_orders DESC, customer_spending DESC;
