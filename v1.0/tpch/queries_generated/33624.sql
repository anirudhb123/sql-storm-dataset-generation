WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
PopularParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
),
RankedCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
)
SELECT 
    p.p_name, 
    n.n_name AS supplier_nation, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT sh.s_name) AS suppliers,
    rc.c_name AS top_customer
FROM PopularParts p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN supplier sh ON l.l_suppkey = sh.s_suppkey
LEFT JOIN nation n ON sh.s_nationkey = n.n_nationkey
LEFT JOIN RankedCustomers rc ON o.o_custkey = rc.c_custkey AND rc.rank = 1
GROUP BY p.p_name, n.n_name, rc.c_name
HAVING SUM(l.l_extendedprice) IS NOT NULL
ORDER BY sales DESC
LIMIT 10;
