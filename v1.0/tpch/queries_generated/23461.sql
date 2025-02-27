WITH RECURSIVE part_supplier AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        ps.ps_supplycost, 
        ps.ps_availqty, 
        s.s_name AS supplier_name,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > 0
), 
customer_orders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderstatus, 
        COUNT(l.l_linenumber) AS items_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        CASE 
            WHEN o.o_orderdate < '2020-01-01' THEN 'Historically High Value'
            ELSE 'Recent Activity' 
        END AS order_category
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus, o.o_orderdate
)
SELECT 
    r.r_name AS region_name, 
    nt.n_name AS nation_name, 
    p.p_name AS part_name,
    COUNT(DISTINCT cs.c_custkey) AS customer_count,
    SUM(CASE WHEN cs.total_order_value IS NOT NULL THEN cs.total_order_value ELSE 0 END) AS total_revenue,
    MAX(ps.supplier_name) AS highest_cost_supplier,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE NULL END) AS total_returns,
    AVG(LEAST(ws.total_order_value, 1000)) AS avg_value_under_1000
FROM 
    region r
JOIN 
    nation nt ON nt.n_regionkey = r.r_regionkey
JOIN 
    supplier s ON s.s_nationkey = nt.n_nationkey
JOIN 
    part p ON p.p_partkey IN (SELECT ps.ps_partkey FROM part_supplier ps WHERE ps.rn = 1)
LEFT JOIN 
    customer_orders cs ON cs.o_orderkey IN (SELECT o_orderkey FROM orders WHERE o_orderstatus = 'F')
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
CROSS JOIN 
    (SELECT DISTINCT SUM(total_order_value) OVER (PARTITION BY c_custkey) AS total_order_value FROM customer_orders) AS ws
WHERE 
    p.p_size >= 10 AND 
    p.p_retailprice IS NOT NULL
GROUP BY 
    r.r_name, nt.n_name, p.p_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_revenue DESC, region_name, nation_name, part_name;
