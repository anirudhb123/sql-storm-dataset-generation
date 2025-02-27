WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_clerk ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
),
supplier_lines AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_extendedprice) AS avg_price
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey AND ps.ps_suppkey = l.l_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
customer_rank AS (
    SELECT 
        c.c_custkey,
        DENSE_RANK() OVER (ORDER BY c.c_acctbal DESC) AS cust_rank
    FROM 
        customer c
)
SELECT 
    r.r_name,
    n.n_name,
    p.p_name,
    COALESCE(SUM(sl.total_quantity), 0) AS total_supplied_quantity,
    COALESCE(AVG(sl.avg_price), 0) AS average_supply_price,
    COUNT(DISTINCT ro.o_orderkey) AS order_count,
    COUNT(DISTINCT cr.c_custkey) AS high_value_customers
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    supplier_lines sl ON s.s_suppkey = sl.ps_suppkey
LEFT JOIN 
    ranked_orders ro ON s.s_suppkey = ro.o_orderkey
LEFT JOIN 
    customer_rank cr ON cr.c_custkey = ro.o_custkey AND cr.cust_rank <= 10
INNER JOIN 
    part p ON sl.ps_partkey = p.p_partkey
WHERE 
    (p.p_brand = 'BrandX' OR p.p_retailprice > 100)
GROUP BY 
    r.r_name, n.n_name, p.p_name
HAVING 
    SUM(sl.total_quantity) IS NOT NULL 
ORDER BY 
    total_supplied_quantity DESC, average_supply_price DESC;
