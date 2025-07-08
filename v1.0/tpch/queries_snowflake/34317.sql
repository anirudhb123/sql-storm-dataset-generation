WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        1 AS level
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT 
        co.c_custkey,
        co.c_name,
        co.c_acctbal,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        co.level + 1
    FROM 
        CustomerOrders co
    JOIN 
        orders o ON co.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' AND co.level < 3
)
SELECT 
    c.c_custkey,
    c.c_name,
    COUNT(o.o_orderkey) AS total_orders,
    SUM(o.o_totalprice) AS total_spent,
    AVG(o.o_totalprice) AS avg_spent,
    COUNT(DISTINCT l.l_orderkey) AS total_lineitems,
    COALESCE(SUM(ps.ps_supplycost * l.l_quantity), 0) AS total_supply_cost,
    MAX(o.o_orderdate) AS last_order_date,
    ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_within_nation,
    CASE 
        WHEN SUM(o.o_totalprice) > 10000 THEN 'High Value'
        WHEN SUM(o.o_totalprice) BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    customer c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey 
GROUP BY 
    c.c_custkey, c.c_name, c.c_nationkey
HAVING 
    SUM(o.o_totalprice) IS NOT NULL AND COUNT(o.o_orderkey) > 0
ORDER BY 
    total_spent DESC
LIMIT 10;
