WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_type
), 
top_parts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.total_supply_cost,
        rp.rank
    FROM 
        ranked_parts rp
    WHERE 
        rp.rank <= 3
), 
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    co.c_name,
    co.order_count,
    co.total_spent,
    tp.p_name,
    tp.total_supply_cost
FROM 
    customer_orders co
JOIN 
    lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)
JOIN 
    top_parts tp ON l.l_partkey = tp.p_partkey
ORDER BY 
    co.total_spent DESC, tp.total_supply_cost DESC
LIMIT 10;
