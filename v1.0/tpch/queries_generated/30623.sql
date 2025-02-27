WITH RECURSIVE order_hierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS depth
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
    UNION ALL
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        oh.depth + 1
    FROM 
        orders o
    JOIN 
        order_hierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE 
        oh.depth < 5
),
supplier_summary AS (
    SELECT 
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(s.s_acctbal) AS avg_acct_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
customer_order_totals AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS num_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
)
SELECT 
    r.r_name,
    COALESCE(oht.num_orders, 0) AS orders_count,
    COALESCE(oht.total_spent, 0.00) AS total_spent,
    COALESCE(ss.total_available_qty, 0) AS total_available_qty,
    COALESCE(ss.avg_acct_balance, 0.00) AS avg_acct_balance
FROM 
    region r
LEFT JOIN 
    customer_order_totals oht ON r.r_regionkey = oht.c_nationkey
LEFT JOIN 
    supplier_summary ss ON r.r_regionkey = ss.s_nationkey
WHERE 
    (oht.total_spent > 1000 OR ss.total_available_qty > 5000)
ORDER BY 
    r.r_name ASC;
