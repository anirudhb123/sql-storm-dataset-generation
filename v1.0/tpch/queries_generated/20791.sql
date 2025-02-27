WITH RecursiveSupplier AS (
    SELECT s.s_suppkey, s.s_name, 
           SUM(CASE WHEN ps.ps_availqty IS NOT NULL THEN ps.ps_availqty ELSE 0 END) AS total_available,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(ps.ps_supplycost)) AS rn
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
    HAVING COUNT(o.o_orderkey) > 5 AND c.c_acctbal > 1000.00
),
ExtendedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus IN ('F', 'O')
)
SELECT DISTINCT
    ns.n_name AS nation_name,
    ps.p_name AS part_name,
    rs.total_available,
    hc.c_name AS customer_name,
    eo.o_totalprice,
    eo.order_rank,
    COALESCE((SELECT AVG(l.l_extendedprice) 
              FROM lineitem l 
              WHERE l.l_orderkey = eo.o_orderkey AND l.l_discount > 0.05), 0) AS avg_discounted_price
FROM nation ns
JOIN region r ON ns.n_regionkey = r.r_regionkey
JOIN supplier s ON ns.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN RecursiveSupplier rs ON s.s_suppkey = rs.s_suppkey
JOIN HighValueCustomers hc ON s.s_nationkey = hc.c_nationkey
JOIN ExtendedOrders eo ON hc.c_custkey = eo.o_orderkey
WHERE eo.o_totalprice > 2000.00 
  AND ns.n_name NOT LIKE '%land%'
ORDER BY rs.total_available DESC, eo.order_rank, ps.p_name;
