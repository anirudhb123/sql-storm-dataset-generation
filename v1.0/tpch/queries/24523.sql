
WITH RECURSIVE CTE_Orders AS (
    SELECT o_orderkey, o_totalprice, o_orderdate, o_orderstatus
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_totalprice + CTE.o_totalprice, o.o_orderdate, o.o_orderstatus
    FROM orders o
    JOIN CTE_Orders CTE ON o.o_custkey = CTE.o_orderkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate > CTE.o_orderdate
),
CustomerWithBackorders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, COUNT(o.o_orderkey) AS backorder_count
    FROM customer c
    LEFT JOIN CTE_Orders o ON c.c_custkey = o.o_orderkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
    HAVING COUNT(o.o_orderkey) > 0
    OR c.c_acctbal IS NULL
),
SupplierRegions AS (
    SELECT n.n_regionkey, r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_regionkey, r.r_name
    HAVING COUNT(DISTINCT s.s_suppkey) > 1
)
SELECT p.p_partkey, p.p_name, COALESCE(p.p_size, 0) AS size,
       (SELECT MAX(l.l_extendedprice)
        FROM lineitem l
        WHERE l.l_partkey = p.p_partkey AND l.l_shipdate BETWEEN DATE '1998-10-01' - INTERVAL '1 year' AND DATE '1998-10-01') AS max_price,
       (SELECT SUM(ps.ps_availqty)
        FROM partsupp ps
        WHERE ps.ps_partkey = p.p_partkey
        AND (SELECT COUNT(*) FROM supplier s WHERE s.s_suppkey = ps.ps_suppkey) > 1) AS total_avail_qty,
       (SELECT COUNT(DISTINCT o.o_orderkey)
        FROM orders o
        JOIN CustomerWithBackorders cb ON o.o_custkey = cb.c_custkey
        WHERE o.o_orderstatus IN ('O', 'F')
        AND cb.backorder_count > 0) AS order_count,
       r.r_name AS region_name
FROM part p
LEFT JOIN SupplierRegions r ON r.supplier_count > 0
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
  AND EXISTS (SELECT 1 FROM nation n WHERE n.n_name = 'USA' AND n.n_nationkey IN (SELECT s.s_nationkey FROM supplier s WHERE s.s_acctbal > 1000))
ORDER BY p.p_partkey DESC, size;
