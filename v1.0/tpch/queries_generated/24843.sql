WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank,
           COUNT(ps.ps_availqty) OVER (PARTITION BY s.s_suppkey) AS supply_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           SUM(l.l_quantity) AS total_quantity,
           COUNT(l.l_orderkey) AS line_item_count,
           MAX(o.o_orderdate) AS last_order_date,
           CASE 
               WHEN o.o_orderstatus = 'F' THEN 'Finalized'
               WHEN o.o_orderstatus = 'P' THEN 'Pending'
               ELSE 'Unknown'
           END AS order_status
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderstatus
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name,
           CASE 
               WHEN p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) THEN 'Expensive'
               ELSE 'Affordable'
           END AS price_category,
           COUNT(DISTINCT ps.ps_suppkey) AS supplying_supp_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
)
SELECT p.p_name, r.r_name, o.last_order_date, 
       COALESCE(s.s_name, 'No Supplier') AS supplier_name,
       p.price_category, o.total_quantity,
       CASE WHEN fs.supplying_supp_count > 1 THEN 'Highly Supplied' ELSE 'Singly Supplied' END AS supply_level,
       CASE WHEN (o.o_totalprice IS NULL OR p.p_size IS NULL) THEN 'Undefined' ELSE 'Defined' END AS price_info,
       SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY s.s_nationkey ORDER BY o.last_order_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM FilteredParts p
LEFT JOIN RankedSuppliers s ON s.rank <= 3
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN OrderStats o ON o.o_totalprice > 1000
LEFT JOIN lineitem l ON l.l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = 12345)
WHERE p.p_size BETWEEN 10 AND 20
  AND (s.s_acctbal IS NULL OR s.s_acctbal > 5000)
ORDER BY r.r_name, o.last_order_date DESC, total_quantity DESC
FETCH FIRST 50 ROWS ONLY;
