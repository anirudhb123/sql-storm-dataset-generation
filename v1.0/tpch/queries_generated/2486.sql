WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
),
supply_info AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        (ps.ps_availqty * ps.ps_supplycost) AS total_supply_value
    FROM 
        partsupp ps
    WHERE 
        ps.ps_availqty > 0
),
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    c.c_name AS customer_name,
    o.o_orderkey AS order_key,
    o.o_orderdate AS order_date,
    CASE 
        WHEN o.o_orderstatus = 'O' THEN 'Open'
        WHEN o.o_orderstatus = 'F' THEN 'Finished'
        ELSE 'Unknown' 
    END AS order_status,
    COALESCE(si.total_supply_value, 0) AS supply_value,
    cts.total_spent,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS customer_order_rank
FROM 
    customer_order_summary cts
JOIN 
    ranked_orders o ON cts.total_orders > 0 AND o.o_orderkey IN (SELECT o2.o_orderkey FROM orders o2 WHERE o2.o_custkey = cts.c_custkey)
LEFT JOIN 
    supply_info si ON si.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
WHERE 
    cts.total_spent IS NOT NULL
ORDER BY 
    c.c_name, o.o_orderdate DESC;
