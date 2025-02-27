WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.nationkey = sh.nationkey
    WHERE sh.level < 5
), 
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c 
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 50000
), 
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(*) AS item_count,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM lineitem l
    GROUP BY l.l_orderkey
),
SuppliersWithOrders AS (
    SELECT s.s_suppkey, s.s_name, o.o_orderkey, l.total_price
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey 
    WHERE o.o_orderstatus = 'O' AND l.l_shipdate > '2023-01-01'
)
SELECT 
    r.r_name,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
    SUM(ts.total_spent) AS total_customer_spent,
    AVG(lis.total_price) AS avg_total_price,
    MAX(lis.item_count) AS max_items_per_order
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN TopCustomers ts ON ts.c_custkey = ANY (
    SELECT c.c_custkey
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_totalprice > 1000
)
LEFT JOIN LineItemStats lis ON lis.l_orderkey = ANY (
    SELECT o.o_orderkey
    FROM orders o 
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND CURRENT_DATE
)
GROUP BY r.r_name
ORDER BY supplier_count DESC, total_customer_spent DESC;
