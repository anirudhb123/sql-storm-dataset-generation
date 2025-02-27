WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate > cast('1998-10-01' as date) - INTERVAL '1 year'
),
customer_orders AS (
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
),
high_value_part AS (
    SELECT 
        ps.ps_partkey,
        MAX(ps.ps_supplycost) AS max_supplycost,
        SUM(l.l_quantity) AS total_quantity_sold
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_partkey
    HAVING 
        MAX(ps.ps_supplycost) > (SELECT AVG(ps_supplycost) FROM partsupp)
)
SELECT 
    r.o_orderdate,
    co.c_name,
    hp.ps_partkey,
    hp.total_quantity_sold,
    COALESCE(co.total_spent, 0) AS total_spent,
    CASE 
        WHEN r.o_orderstatus = 'F' THEN 'Finished'
        WHEN r.o_orderstatus = 'P' THEN 'Pending'
        ELSE 'Other'
    END AS order_status_description
FROM 
    ranked_orders r
JOIN 
    customer_orders co ON r.o_orderkey = (SELECT MAX(o.o_orderkey) FROM orders o WHERE o.o_custkey = co.c_custkey)
LEFT JOIN 
    high_value_part hp ON hp.total_quantity_sold > 1000
WHERE 
    r.order_rank = 1
ORDER BY 
    r.o_orderdate DESC, co.total_spent DESC;