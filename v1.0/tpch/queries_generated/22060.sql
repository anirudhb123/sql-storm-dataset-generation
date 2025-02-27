WITH ranked_orders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    INNER JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE 
        c.c_acctbal IS NOT NULL 
        AND c.c_mktsegment = 'BUILDING'
),
supply_analysis AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_availqty) < (SELECT AVG(ps_availqty) FROM partsupp)
),
part_supplier_info AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        COALESCE(ps.total_avail_qty, 0) AS total_avail_qty,
        COALESCE(ps.total_supply_cost, 0) AS total_supply_cost
    FROM 
        part p
    LEFT JOIN supply_analysis ps ON p.p_partkey = ps.ps_partkey
),
customer_order_info AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus <> 'F'
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    c.c_name,
    COALESCE(p.part_supplier_info, 'Unknown') AS supplier_details,
    (SELECT AVG(total_spent) FROM customer_order_info) AS avg_spent,
    CAST(prn AS VARCHAR) AS rank_order_info
FROM 
    customer_order_info coi
JOIN 
    customer c ON c.c_custkey = coi.c_custkey
LEFT JOIN 
    part_supplier_info p ON p.total_avail_qty = (SELECT MAX(total_avail_qty) FROM part_supplier_info)
CROSS JOIN 
    (SELECT ROW_NUMBER() OVER () AS prn FROM ranked_orders) rank_info
WHERE 
    c.c_acctbal IS NOT NULL
    AND EXISTS (
        SELECT 1 
        FROM orders o 
        WHERE o.o_custkey = c.c_custkey 
          AND o.o_orderdate BETWEEN '2022-01-01' AND CURRENT_DATE
    )
ORDER BY 
    c.c_name, c.c_custkey;
