WITH RECURSIVE
  SupplyChain AS (
    SELECT ps.suppkey AS supplier_id, p.p_partkey, SUM(ps.ps_availqty) AS total_availqty
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.suppkey, p.p_partkey
    HAVING SUM(ps.ps_availqty) IS NOT NULL AND SUM(ps.ps_availqty) > 0
  ),
  RankedOrders AS (
    SELECT
      o.o_orderkey,
      o.o_totalprice,
      RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_totalprice > (
      SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate < CURRENT_DATE
    )
  ),
  CustomerInfo AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, o.o_orderkey
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > (
      SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_mktsegment = c.c_mktsegment
    )
  )
SELECT
  r.n_name AS nation_name,
  COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
  COUNT(DISTINCT o.o_orderkey) AS total_orders,
  MAX(o.o_totalprice) AS max_order_price,
  COUNT(DISTINCT c.c_custkey) AS unique_customers
FROM nation r
LEFT JOIN supplier s ON r.n_nationkey = s.s_nationkey
LEFT JOIN SupplyChain sc ON s.s_suppkey = sc.supplier_id
LEFT JOIN lineitem l ON sc.p_partkey = l.l_partkey
LEFT JOIN RankedOrders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN CustomerInfo c ON o.o_orderkey = c.o_orderkey
GROUP BY r.n_name
HAVING MAX(o.o_totalprice) IS NOT NULL
  AND COUNT(DISTINCT c.c_custkey) > (
    SELECT COUNT(DISTINCT c2.c_custkey)
    FROM customer c2
    WHERE c2.c_acctbal IS NOT NULL
  )
ORDER BY total_quantity DESC, nation_name
FETCH FIRST 10 ROWS ONLY;
