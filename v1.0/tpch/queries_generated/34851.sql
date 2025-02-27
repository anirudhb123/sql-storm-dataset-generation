WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_size, p_retailprice, 1 AS level
    FROM part
    WHERE p_size >= 10

    UNION ALL

    SELECT p.p_partkey, p.p_name, p.p_size, p.p_retailprice * 0.9 AS discounted_price, ph.level + 1
    FROM part p
    JOIN PartHierarchy ph ON p.p_size < ph.p_size
    WHERE ph.level < 5
), 
SupplierOrderStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT *,
           RANK() OVER (ORDER BY total_sales DESC) as sales_rank
    FROM SupplierOrderStats
)
SELECT 
    ph.p_partkey,
    ph.p_name,
    ph.level,
    ph.discounted_price,
    ts.s_name AS top_supplier,
    ts.total_sales,
    ts.total_orders,
    ts.avg_order_value
FROM PartHierarchy ph
LEFT JOIN TopSuppliers ts ON ts.sales_rank = 1
WHERE ph.discounted_price IS NOT NULL
  AND ph.level <= 3
  AND EXISTS (
      SELECT 1
      FROM nation n
      WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = 1)
        AND n.n_name LIKE 'A%'
  )
ORDER BY ph.discounted_price DESC
LIMIT 100;
