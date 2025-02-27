WITH supplier_stats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(s.s_acctbal) AS avg_acct_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
order_details AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        l.l_quantity, 
        l.l_discount,
        l.l_extendedprice * (1 - l.l_discount) AS discounted_price,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_linenumber) AS line_number
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
),
order_summary AS (
    SELECT 
        od.o_orderkey,
        SUM(od.discounted_price) AS total_discounted_price,
        COUNT(DISTINCT od.line_number) AS line_count
    FROM 
        order_details od
    GROUP BY 
        od.o_orderkey
)
SELECT 
    r.r_name,
    n.n_name,
    s.s_name,
    COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(os.total_discounted_price, 0) AS total_discounted_sales,
    os.line_count,
    CASE 
        WHEN os.total_discounted_price > 1000 THEN 'High Value'
        WHEN os.total_discounted_price BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS sales_category
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    supplier_stats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    order_summary os ON os.o_orderkey = (SELECT MIN(o_orderkey) FROM orders o WHERE o.o_custkey = s.s_suppkey)
WHERE 
    r.r_name LIKE '%South%'
ORDER BY 
    r.r_name, total_supply_cost DESC, total_discounted_sales DESC;
