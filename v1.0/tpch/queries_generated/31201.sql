WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.orderkey, o.custkey, o.totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderstatus = 'O' AND oh.level < 5
),
SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
),
ProductRanked AS (
    SELECT p.p_partkey, p.p_name, RANK() OVER (ORDER BY SUM(li.l_extendedprice) DESC) AS price_rank
    FROM part p
    JOIN lineitem li ON p.p_partkey = li.l_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    c.c_name AS customer_name,
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    oh.o_orderkey AS order_key,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue,
    COUNT(*) OVER (PARTITION BY c.c_custkey) AS order_count,
    rh.level AS hierarchy_level,
    CASE 
        WHEN SUM(li.l_tax) IS NULL THEN 'No Tax'
        ELSE CONCAT('Tax: ', SUM(li.l_tax))
    END AS tax_info,
    pr.price_rank
FROM 
    lineitem li
JOIN 
    orders oh ON li.l_orderkey = oh.o_orderkey
JOIN 
    customer c ON oh.o_custkey = c.c_custkey
LEFT JOIN 
    SupplierInfo s ON li.l_suppkey = s.s_suppkey
RIGHT JOIN 
    ProductRanked pr ON li.l_partkey = pr.p_partkey
JOIN 
    OrderHierarchy rh ON oh.o_orderkey = rh.o_orderkey
WHERE 
    li.l_shipdate >= '2022-01-01'
    AND (li.l_returnflag = 'N' OR li.l_returnflag IS NULL)
GROUP BY 
    c.c_name, s.s_name, p.p_name, oh.o_orderkey, rh.level, pr.price_rank
ORDER BY 
    revenue DESC, customer_name;
