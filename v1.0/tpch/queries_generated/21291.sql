WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, 
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, 
           SUM(ps.ps_availqty) OVER (PARTITION BY s.s_suppkey) AS ps_availqty,
           rn
    FROM SupplyChain sc
    JOIN supplier s ON sc.s_suppkey = s.s_suppkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty IS NOT NULL
), 

OrderDetails AS (
    SELECT o.o_orderkey, c.c_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           DENSE_RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS price_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN DATE '2023-10-01' AND DATE '2023-10-31'
          AND l.l_returnflag = 'R'
    GROUP BY o.o_orderkey, c.c_custkey
), 

SupplierSummary AS (
    SELECT sc.s_suppkey, sc.s_name, SUM(sc.ps_availqty) AS total_avail_qty
    FROM SupplyChain sc
    GROUP BY sc.s_suppkey, sc.s_name
)
SELECT DISTINCT r.r_name, 
       CASE 
           WHEN ss.total_avail_qty IS NULL THEN 'No Supply'
           ELSE 'Available'
       END AS supply_status,
       od.total_price, od.price_rank
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierSummary ss ON n.n_nationkey = ss.s_suppkey
JOIN OrderDetails od ON ss.s_suppkey = od.o_orderkey
WHERE r.r_comment LIKE '%important%'
      AND (od.total_price IS NOT NULL OR ss.total_avail_qty IS NULL)
ORDER BY supply_status DESC, od.price_rank
FETCH FIRST 10 ROWS ONLY;
