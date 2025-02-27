WITH RECURSIVE customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
part_supplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS average_cost
    FROM 
        part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size BETWEEN 1 AND 10)
    GROUP BY 
        p.p_partkey, p.p_name
),
best_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice) AS total_sales
    FROM 
        supplier s
    JOIN lineitem l ON s.s_suppkey = l.l_suppkey
    WHERE 
        l.l_shipdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(l.l_extendedprice) > 10000
),
ranked_suppliers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        best_suppliers
)
SELECT 
    co.c_name,
    co.order_count,
    co.total_spent,
    ps.p_name,
    ps.total_available,
    ps.average_cost,
    rs.s_name AS top_supplier,
    rs.sales_rank
FROM 
    customer_orders co
JOIN part_supplier ps ON co.order_count > 5 AND ps.total_available IS NOT NULL
LEFT JOIN ranked_suppliers rs ON co.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_name LIKE '%a%')
WHERE 
    (ps.average_cost IS NOT NULL OR co.total_spent > 5000) 
    AND co.total_spent IS NOT NULL
ORDER BY 
    co.total_spent DESC, ps.average_cost ASC
LIMIT 100;
