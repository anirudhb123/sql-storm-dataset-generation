WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_custkey, c.c_name,
           1 AS Level
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, c.c_custkey, c.c_name,
           Level + 1
    FROM OrderHierarchy oh
    JOIN orders o ON oh.o_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'F'
    AND Level < 5
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_availqty,
           AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplyvalue,
           RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplyRank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, COUNT(DISTINCT l.l_linenumber) AS line_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-03-31'
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT rh.o_orderkey, rh.o_orderdate, rh.o_totalprice, rh.c_name AS customer_name,
       ps.p_name AS part_name, ps.total_availqty, ss.s_name AS supplier_name,
       ss.total_supplyvalue, ROW_NUMBER() OVER (PARTITION BY rh.o_orderkey ORDER BY ps.total_availqty DESC) AS PartRank,
       CASE WHEN l.l_discount > 0.1 THEN 'High Discount' ELSE 'Regular' END AS DiscountCategory
FROM OrderHierarchy rh
LEFT JOIN RecentOrders o ON rh.o_orderkey = o.o_orderkey
LEFT JOIN PartSupplier ps ON ps.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = rh.o_orderkey)
LEFT JOIN RankedSuppliers ss ON ss.SupplyRank <= 10
WHERE rh.Level = 1 AND COALESCE(o.line_count, 0) > 0
ORDER BY rh.o_orderdate DESC, ps.total_availqty DESC;
