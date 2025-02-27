WITH RECURSIVE top_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
total_orders AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
),
average_order_size AS (
    SELECT 
        c.c_custkey,
        AVG(lo.l_extendedprice * (1 - lo.l_discount)) AS avg_order_amount
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem lo ON o.o_orderkey = lo.l_orderkey
    GROUP BY 
        c.c_custkey
),
supply_summary AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    c.c_name AS customer_name,
    c.c_acctbal AS account_balance,
    o.order_count AS total_orders,
    o.total_spent AS total_spent,
    a.avg_order_amount AS average_order_value,
    s.total_available AS total_available_supply,
    s.avg_supply_cost AS average_supply_cost,
    CASE 
        WHEN o.total_spent > 1000 THEN 'High Value' 
        ELSE 'Low Value' 
    END AS customer_value_segment
FROM 
    customer c
JOIN 
    total_orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    average_order_size a ON c.c_custkey = a.c_custkey
LEFT JOIN 
    supply_summary s ON s.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey IN (SELECT s_suppkey FROM top_suppliers))
WHERE 
    c.c_acctbal IS NOT NULL 
    AND o.order_count > 5
ORDER BY 
    o.total_spent DESC
LIMIT 50;
