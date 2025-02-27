WITH supplier_costs AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey
),
high_cost_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sc.total_supply_cost,
        sc.part_count
    FROM 
        supplier s
    JOIN 
        supplier_costs sc ON s.s_suppkey = sc.s_suppkey
    WHERE 
        sc.total_supply_cost > (
            SELECT AVG(total_supply_cost) FROM supplier_costs
        )
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
filtered_customers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        CASE 
            WHEN co.total_spent > 10000 THEN 'High Value'
            WHEN co.total_spent BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        customer_orders co
)
SELECT 
    r.r_name,
    nc.n_name AS nation,
    hs.s_name AS supplier_name,
    f.total_spent AS total_spent,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY f.total_spent DESC) AS rank_customer
FROM 
    region r
LEFT JOIN 
    nation nc ON r.r_regionkey = nc.n_regionkey
LEFT JOIN 
    high_cost_suppliers hs ON nc.n_nationkey = hs.s_suppkey
LEFT JOIN 
    filtered_customers f ON hs.s_suppkey = f.c_custkey
WHERE 
    f.customer_value = 'High Value' OR f.customer_value IS NULL
ORDER BY 
    r.r_name, rank_customer;
