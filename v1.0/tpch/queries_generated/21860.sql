WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
), 
customer_details AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        s.s_acctbal,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        supplier s ON c.c_nationkey = s.s_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey, s.s_acctbal
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 2
), 
part_details AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        COALESCE(NULLIF(MIN(ps.ps_availqty), 0), NULL) AS min_availqty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
), 
filtered_parts AS (
    SELECT 
        p.*,
        CASE 
            WHEN p.p_retailprice < 20 THEN 'Cheap'
            WHEN p.p_retailprice BETWEEN 20 AND 100 THEN 'Moderate'
            ELSE 'Expensive'
        END AS price_category
    FROM 
        part_details p
    WHERE 
        p.min_availqty IS NOT NULL
)
SELECT 
    c.c_name,
    o.o_orderkey,
    o.o_totalprice,
    p.p_name,
    p.price_category,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS customer_order_rank
FROM 
    customer_details c
JOIN 
    ranked_orders o ON c.total_orders > 5 AND o.o_orderkey IN (SELECT o2.o_orderkey FROM orders o2 WHERE o2.o_orderdate < '1996-01-01')
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    filtered_parts p ON l.l_partkey = p.p_partkey
WHERE 
    p.total_supplycost IS NOT NULL AND
    o.o_totalprice > (SELECT AVG(o3.o_totalprice) FROM orders o3 WHERE o3.o_orderstatus = 'O')
ORDER BY 
    c.c_name, customer_order_rank, o.o_orderkey;
