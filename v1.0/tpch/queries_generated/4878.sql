WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        DENSE_RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
),
customer_spending AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spending
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
supplier_parts AS (
    SELECT 
        s.s_suppkey,
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, p.p_partkey
)
SELECT 
    r.r_name,
    n.n_name,
    COALESCE(SUM(lp.l_discount * lp.l_extendedprice), 0) AS total_discounted_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(cs.total_spending) AS avg_customer_spending
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem lp ON o.o_orderkey = lp.l_orderkey
LEFT JOIN 
    ranked_orders ro ON o.o_orderkey = ro.o_orderkey
LEFT JOIN 
    customer_spending cs ON c.c_custkey = cs.c_custkey
LEFT JOIN 
    supplier_parts sp ON lp.l_suppkey = sp.s_suppkey OR sp.total_available IS NULL 
WHERE 
    (ro.rank <= 5 OR o.o_totalprice > 1000)
GROUP BY 
    r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    total_discounted_sales DESC;
