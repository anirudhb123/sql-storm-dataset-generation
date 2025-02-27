WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
RankedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rn,
        SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY l.l_orderkey) AS total_price
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
),
CustomerOrders AS (
    SELECT 
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_name
    HAVING SUM(o.o_totalprice) > 50000
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region,
    c.c_name AS customer_name,
    co.order_count,
    co.total_spent,
    sh.level AS supplier_level
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN CustomerOrders co ON co.c_name IN (
    SELECT DISTINCT c_name 
    FROM CustomerOrders 
    WHERE total_spent > 60000
)
JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
JOIN RankedLineItems li ON li.l_orderkey IN (
    SELECT o_orderkey 
    FROM orders 
    WHERE o_orderdate >= '2023-01-01'
)
WHERE n.n_comment IS NOT NULL
ORDER BY total_spent DESC, customer_name;
