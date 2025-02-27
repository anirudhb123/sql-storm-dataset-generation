WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, 
           1 AS depth
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, 
           oh.depth + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_orderkey
    WHERE o.o_orderdate < DATE '2023-01-01'
),
SupplierRegion AS (
    SELECT s.s_suppkey, r.r_name, SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, r.r_name
),
CustomerBalance AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers,
        AVG(l.l_qty) FILTER (WHERE l.l_returnflag = 'N') AS avg_quantity_non_returned
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
)
SELECT 
    oh.o_orderkey,
    oh.o_orderstatus,
    oh.depth,
    COALESCE(c.balances, 0) AS customer_balance,
    CASE 
        WHEN od.net_sales > 10000 THEN 'High Value'
        WHEN od.net_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS order_value_category,
    sr.r_name AS supplier_region,
    sr.total_supplycost,
    od.avg_quantity_non_returned
FROM OrderHierarchy oh
LEFT JOIN CustomerBalance c ON oh.o_orderkey = c.c_custkey
LEFT JOIN OrderDetails od ON oh.o_orderkey = od.o_orderkey
LEFT JOIN SupplierRegion sr ON sr.s_suppkey = (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_orderkey = oh.o_orderkey
    LIMIT 1
)
WHERE oh.depth > 1 
ORDER BY oh.o_orderdate DESC, customer_balance DESC;
