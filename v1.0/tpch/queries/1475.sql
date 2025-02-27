
WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F') 
      AND o.o_totalprice > (
          SELECT AVG(o2.o_totalprice) 
          FROM orders o2 
          WHERE o2.o_orderstatus = o.o_orderstatus
      )
),
SupplierCosts AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT
    p.p_partkey,
    p.p_name,
    COALESCE(rc.total_supplycost, 0) AS supplier_cost,
    ROUND((p.p_retailprice - COALESCE(rc.total_supplycost, 0)), 2) AS profit_margin,
    r.r_name AS region_name,
    n.n_name AS nation_name
FROM part p
LEFT JOIN SupplierCosts rc ON p.p_partkey = rc.ps_partkey
LEFT JOIN supplier s ON s.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey = p.p_partkey 
      AND ps.ps_availqty > 0
)
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_size BETWEEN 10 AND 50
  AND p.p_name LIKE '%Widget%'
  AND r.r_name IS NOT NULL
  AND (s.s_acctbal IS NULL OR s.s_acctbal > 1000)
  AND EXISTS (
      SELECT 1
      FROM RankedOrders ro
      WHERE ro.o_orderkey IN (
          SELECT l.l_orderkey
          FROM lineitem l
          WHERE l.l_partkey = p.p_partkey
      )
      AND ro.price_rank <= 5
  )
ORDER BY profit_margin DESC
LIMIT 10;
