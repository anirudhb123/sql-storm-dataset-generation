WITH RECURSIVE SuppHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_suppkey IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SuppHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_suppkey != sh.s_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY c.c_custkey, c.c_name
),
PartSupplies AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty IS NOT NULL
),
RankedSales AS (
    SELECT li.l_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS net_sales,
           ROW_NUMBER() OVER (PARTITION BY li.l_orderkey ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS sale_rank
    FROM lineitem li
    WHERE li.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY li.l_orderkey
),
SupplierStats AS (
    SELECT s.s_suppkey, COUNT(DISTINCT ps.ps_partkey) AS total_parts,
           SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
)
SELECT c.c_name AS customer_name, co.total_spent, ps.p_name,
       ss.total_parts, ss.total_supplycost,
       r.net_sales, (CASE WHEN r.net_sales IS NULL THEN 'No Sale' ELSE 'Sale' END) AS sale_status
FROM CustomerOrders co
JOIN PartSupplies ps ON ps.ps_availqty > 100
LEFT JOIN SupplierStats ss ON ss.total_supplycost > 10000
FULL OUTER JOIN RankedSales r ON r.sale_rank = 1
WHERE co.total_spent > 1000
ORDER BY co.total_spent DESC;
