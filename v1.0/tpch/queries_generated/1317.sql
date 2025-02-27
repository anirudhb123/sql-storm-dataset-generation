WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l.l_shipdate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
customer_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    GROUP BY 
        c.c_custkey, c.c_name
),
nation_supplier AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
),
final_report AS (
    SELECT 
        cs.c_name,
        cs.order_count,
        cs.total_spent,
        ro.total_price,
        ns.supplier_count
    FROM 
        customer_summary cs
    LEFT JOIN 
        ranked_orders ro ON cs.order_count > 0 AND ro.rn = 1
    LEFT JOIN 
        nation_supplier ns ON ns.supplier_count > 5
)
SELECT 
    fr.c_name AS customer_name,
    fr.order_count AS total_orders,
    COALESCE(fr.total_spent, 0.00) AS total_spent,
    COALESCE(fr.total_price, 0.00) AS last_order_total,
    fr.supplier_count AS suppliers_in_nation
FROM 
    final_report fr
WHERE 
    fr.total_spent > 1000
ORDER BY 
    fr.total_spent DESC, fr.customer_name ASC
LIMIT 10;
