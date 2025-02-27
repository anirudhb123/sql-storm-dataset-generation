WITH regional_stats AS (
    SELECT 
        r.r_name AS region_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name
), ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01'
), customer_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent 
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), high_spenders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COALESCE(cs.total_spent, 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_summary cs ON c.c_custkey = cs.c_custkey
    WHERE 
        c.c_acctbal > 1000
)
SELECT 
    r.region_name,
    hs.c_name,
    hs.total_spent,
    RANK() OVER (ORDER BY hs.total_spent DESC) AS spender_rank
FROM 
    high_spenders hs
JOIN 
    supplier s ON hs.c_custkey = s.s_suppkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    regional_stats r ON s.s_nationkey = r.region_name
WHERE 
    hs.total_spent > (SELECT AVG(total_spent) FROM customer_summary)
ORDER BY 
    r.region_name, spender_rank;
