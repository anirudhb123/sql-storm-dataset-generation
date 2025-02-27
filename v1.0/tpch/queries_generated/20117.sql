WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate,
           CASE 
               WHEN o.o_orderstatus = 'F' THEN 'Completed'
               ELSE 'Pending'
           END AS order_status
    FROM orders o
    WHERE o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
),
MaxLineItem AS (
    SELECT l.l_orderkey, MAX(l.l_extendedprice) AS max_price
    FROM lineitem l
    GROUP BY l.l_orderkey
),
SuppliersWithComments AS (
    SELECT s.s_suppkey, s.s_name,
           COALESCE(NULLIF(s.s_comment, ''), 'No comment available') AS supplier_comment
    FROM supplier s
)
SELECT fo.o_orderkey, fo.order_status, SUM(li.l_quantity) AS total_quantity,
       COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
       MAX(mli.max_price) AS highest_line_item_price,
       STRING_AGG(DISTINCT swc.supplier_comment, '; ') AS supplier_comments
FROM FilteredOrders fo
LEFT JOIN lineitem li ON fo.o_orderkey = li.l_orderkey
LEFT JOIN MaxLineItem mli ON fo.o_orderkey = mli.l_orderkey
LEFT JOIN RankedSuppliers rs ON li.l_suppkey = rs.s_suppkey
LEFT JOIN SuppliersWithComments swc ON rs.s_suppkey = swc.s_suppkey
WHERE fo.o_totalprice IS NOT NULL
  AND (fo.o_totalprice BETWEEN 100 AND 1000 OR fo.o_totalprice IS NULL)
GROUP BY fo.o_orderkey, fo.order_status
HAVING COUNT(DISTINCT rs.s_suppkey) > 0
   OR MAX(mli.max_price) IS NOT NULL
ORDER BY total_quantity DESC, fo.o_orderdate DESC;
