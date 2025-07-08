
WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn,
           DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS dr
    FROM orders o
    WHERE o.o_orderstatus IN ('F', 'O')
),
SupplierProductDetails AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           p.p_partkey,
           p.p_name,
           p.p_brand,
           ps.ps_supplycost,
           ps.ps_availqty,
           CASE WHEN p.p_size IS NULL THEN NULL ELSE p.p_retailprice * p.p_size END AS calculated_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > (SELECT AVG(s1.s_acctbal) FROM supplier s1 WHERE s1.s_nationkey = s.s_nationkey)
    OR s.s_comment LIKE '%special%'
),
AggregatedValues AS (
    SELECT spd.s_suppkey,
           COUNT(spd.p_partkey) AS total_parts,
           SUM(spd.ps_supplycost * spd.ps_availqty) AS total_supplycost,
           SUM(COALESCE(spd.calculated_value, 0)) AS total_calculated_value
    FROM SupplierProductDetails spd
    GROUP BY spd.s_suppkey
)
SELECT ro.o_orderkey,
       ro.o_orderdate,
       ro.o_totalprice,
       av.total_parts,
       av.total_supplycost,
       av.total_calculated_value
FROM RankedOrders ro
FULL OUTER JOIN AggregatedValues av ON ro.o_orderkey = av.s_suppkey
WHERE av.total_supplycost IS NOT NULL
AND av.total_calculated_value > 0
AND NOT EXISTS (SELECT 1 FROM lineitem l WHERE l.l_orderkey = ro.o_orderkey AND l.l_discount > 0.1)
ORDER BY ro.o_orderdate DESC, av.total_supplycost DESC
OFFSET (SELECT COUNT(*) / 2 FROM orders) LIMIT 10;
