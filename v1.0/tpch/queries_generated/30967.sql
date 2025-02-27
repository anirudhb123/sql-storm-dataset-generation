WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, n_comment, 0 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, n.n_comment, nh.level + 1
    FROM nation n
    INNER JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
PartSupplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderData AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(od.total_price) AS customer_spent
    FROM customer c
    JOIN OrderData od ON c.c_custkey = od.o_orderkey
    GROUP BY c.c_custkey, c.c_name
    ORDER BY customer_spent DESC
    LIMIT 10
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(MAX(ps.total_avail), 0) AS max_available,
    COALESCE(SUM(od.total_price), 0) AS total_order_value,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY COALESCE(SUM(od.total_price), 0) DESC) AS row_num,
    CASE 
        WHEN p.p_size IS NULL THEN 'Unknown Size'
        ELSE CONCAT('Size: ', p.p_size)
    END AS size_info
FROM part p
LEFT JOIN PartSupplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN OrderData od ON l.l_orderkey = od.o_orderkey
LEFT JOIN TopCustomers tc ON od.o_orderkey = tc.c_custkey
WHERE p.p_retailprice > (SELECT AVG(p_retailprice) FROM part) 
  AND p.p_brand IS NOT NULL
GROUP BY p.p_partkey, p.p_name, p.p_size
ORDER BY total_order_value DESC,
         max_available DESC,
         size_info;
