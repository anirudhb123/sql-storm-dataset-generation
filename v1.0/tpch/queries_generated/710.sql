WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
),
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey,
        s.s_name
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey,
        c.c_name
),
detailed_lineitems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        (l.l_extendedprice * (1 - l.l_discount)) AS net_price,
        CASE 
            WHEN l.l_returnflag = 'R' THEN 'Returned'
            ELSE 'Sold'
        END AS sale_status
    FROM 
        lineitem l
)
SELECT 
    co.c_name,
    co.total_orders,
    co.total_spent,
    ss.total_available,
    ss.avg_supply_cost,
    ro.o_totalprice,
    ro.o_orderdate
FROM 
    customer_orders co
LEFT JOIN 
    supplier_summary ss ON co.total_orders > 0
JOIN 
    ranked_orders ro ON co.total_orders = (SELECT COUNT(*) FROM orders o WHERE o.o_custkey = co.c_custkey)
WHERE 
    co.total_spent > 10000
ORDER BY 
    co.total_spent DESC
LIMIT 10;

SELECT 
    p.p_name,
    SUM(li.l_extendedprice) AS total_revenue
FROM 
    part p 
JOIN 
    detailed_lineitems li ON p.p_partkey = li.l_partkey
GROUP BY 
    p.p_name
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC;
