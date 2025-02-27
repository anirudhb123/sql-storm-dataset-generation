WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           1 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'UNITED STATES')

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 5
),
PartSales AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
),
TopSellingParts AS (
    SELECT p.p_partkey, p.p_name, ps.total_sales,
           RANK() OVER (ORDER BY ps.total_sales DESC) AS sales_rank
    FROM PartSales ps
    JOIN part p ON ps.p_partkey = p.p_partkey
    WHERE ps.total_sales > (
        SELECT AVG(total_sales) FROM PartSales
    )
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, 
           COUNT(DISTINCT ps.ps_partkey) AS num_parts_supplied,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, 
           o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_seq
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
)
SELECT sh.s_name AS supplier_name,
       ts.p_name AS top_part,
       ss.num_parts_supplied,
       ss.total_supplycost,
       co.c_name AS customer_name,
       co.o_orderdate,
       co.o_totalprice
FROM SupplierHierarchy sh
JOIN TopSellingParts ts ON ts.sales_rank <= 10
JOIN SupplierStats ss ON sh.s_suppkey = ss.s_suppkey
JOIN CustomerOrders co ON co.order_seq <= 5
WHERE ss.num_parts_supplied > 0
  AND co.o_totalprice > 1000
ORDER BY ss.total_supplycost DESC, co.o_orderdate DESC;
