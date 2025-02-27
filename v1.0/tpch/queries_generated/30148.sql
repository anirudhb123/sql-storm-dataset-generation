WITH RECURSIVE supply_chain AS (
    SELECT 
        ps.partkey, 
        ps.suppkey, 
        ps.availqty, 
        ps.supplycost, 
        1 AS level
    FROM 
        partsupp ps
    WHERE 
        ps.availqty > 0
    UNION ALL
    SELECT 
        ps.partkey, 
        ps.suppkey, 
        ps.availqty - 1, 
        ps.supplycost, 
        sc.level + 1
    FROM 
        supply_chain sc
    JOIN 
        partsupp ps ON sc.partkey = ps.partkey AND sc.suppkey = ps.suppkey
    WHERE 
        ps.availqty > 0 AND sc.level < 5
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
    WHERE 
        c.c_acctbal > 1000
    GROUP BY 
        c.c_custkey, c.c_name
),
product_analysis AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        AVG(l.l_extendedprice) AS avg_price,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(DISTINCT l.l_orderkey) AS total_orders
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
region_analysis AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS total_nations,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.customer_order_summary.c_custkey) AS total_customers,
    SUM(pa.total_orders) AS total_product_orders,
    SUM(supply_chain.availqty) AS total_supplied_quantity,
    AVG(pa.avg_price) AS avg_product_price
FROM 
    region_analysis r
LEFT JOIN 
    customer_order_summary c ON r.total_nations = c.total_orders
LEFT JOIN 
    product_analysis pa ON pa.total_quantity > 0
LEFT JOIN 
    supply_chain ON supply_chain.partkey = pa.p_partkey
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10 AND 
    AVG(pa.avg_price) IS NOT NULL
ORDER BY 
    total_product_orders DESC
LIMIT 10;
