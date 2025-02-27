WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 0 AS Level
    FROM customer c
    WHERE c.c_custkey = (SELECT MIN(c2.c_custkey) FROM customer c2)

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.Level + 1
    FROM customer c
    INNER JOIN CustomerHierarchy ch ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = ch.c_nationkey)
    WHERE ch.Level < 3
),

OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
),

FilterSuppliers AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    WHERE ps.ps_supplycost < (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2)
    GROUP BY ps.ps_partkey, ps.ps_suppkey
)

SELECT 
    c.c_name,
    r.r_name AS region,
    COALESCE(SUM(os.total_revenue), 0) AS total_revenue,
    COUNT(DISTINCT ch.c_custkey) AS number_of_customers,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_size, ')')) AS products_supplied,
    CASE 
        WHEN COUNT(DISTINCT ch.c_custkey) > 10 THEN 'High'
        WHEN COUNT(DISTINCT ch.c_custkey) > 5 THEN 'Medium'
        ELSE 'Low' 
    END AS customer_segment
FROM 
    CustomerHierarchy ch
JOIN 
    customer c ON ch.c_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    OrderSummary os ON c.c_custkey = os.o_orderkey
LEFT JOIN 
    partsupp ps ON c.c_nationkey = ps.ps_supkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    FilterSuppliers f ON p.p_partkey = f.ps_partkey
GROUP BY 
    c.c_name, r.r_name
ORDER BY 
    total_revenue DESC, customer_segment ASC
WITH ROLLUP;
