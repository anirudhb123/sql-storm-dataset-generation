WITH regional_suppliers AS (
    SELECT 
        n.n_nationkey,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_name
),
top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
part_stats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.nation_name,
    r.region_name,
    c.c_name AS top_customer_name,
    c.total_spent,
    p.p_name,
    p.total_avail_qty,
    p.avg_supply_cost,
    CASE 
        WHEN p.avg_supply_cost IS NULL THEN 'Cost Data Not Available' 
        ELSE 'Data Available' 
    END AS cost_status
FROM 
    regional_suppliers r
FULL OUTER JOIN 
    top_customers c ON r.n_nationkey = c.c_custkey
LEFT JOIN 
    part_stats p ON p.total_avail_qty > 100
WHERE 
    r.total_acctbal IS NOT NULL
    OR c.total_spent > 10000
ORDER BY 
    r.region_name, c.total_spent DESC;
