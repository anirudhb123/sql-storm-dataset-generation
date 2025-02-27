WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.n_nationkey = sh.n_nationkey
    WHERE sh.level < 3
),
CustomerWithOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_mktsegment, 
           COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_mktsegment
),
TopCustomers AS (
    SELECT c.*, 
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.total_spent DESC) AS rank
    FROM CustomerWithOrders c
)
SELECT 
    p.p_name, 
    p.p_retailprice, 
    s.s_name AS supplier_name,
    rt.r_name AS region_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 5 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer' 
    END AS buyer_category
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region rt ON n.n_regionkey = rt.r_regionkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
WHERE p.p_size BETWEEN 10 AND 20
AND (l.l_returnflag IS NULL OR l.l_returnflag = 'N')
AND o.o_orderstatus = 'O'
GROUP BY p.p_name, p.p_retailprice, s.s_name, rt.r_name
HAVING SUM(l.l_quantity) > 50
UNION ALL
SELECT 
    'Total' AS p_name,
    SUM(p.p_retailprice) AS p_retailprice,
    NULL AS supplier_name,
    NULL AS region_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    NULL AS buyer_category
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
WHERE p.p_container = 'BOX' 
AND l.l_shipdate > DATEADD(month, -6, CURRENT_DATE)
ORDER BY region_name, total_revenue DESC;
