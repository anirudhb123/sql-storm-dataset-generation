WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS depth
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT oh.o_orderkey, o.o_orderdate, o.o_totalprice, depth + 1
    FROM OrderHierarchy oh
    JOIN orders o ON oh.o_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O'
),
SupplierPerformance AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, c.acctbal, ROW_NUMBER() OVER (ORDER BY COALESCE(total_spent, 0) DESC) AS rank
    FROM customer c
    LEFT JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
)
SELECT DISTINCT
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    s.s_name AS supplier_name,
    sp.total_cost,
    COALESCE(tc.total_spent, 0) AS customer_spent,
    rh.depth
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN SupplierPerformance sp ON s.s_suppkey = sp.s_suppkey
LEFT JOIN TopCustomers tc ON tc.c_custkey IN (
    SELECT o.o_custkey
    FROM orders o
    WHERE o.o_orderkey IN (SELECT o_orderkey FROM OrderHierarchy)
)
LEFT JOIN OrderHierarchy rh ON rh.o_orderkey = o.o_orderkey
WHERE p.p_size > 10 
    AND p.p_retailprice BETWEEN 50 AND 150
    AND s.s_nationkey IS NOT NULL
ORDER BY p.p_retailprice DESC, customer_spent ASC;
