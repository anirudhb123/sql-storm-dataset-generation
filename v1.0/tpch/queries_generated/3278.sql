WITH RankedParts AS (
    SELECT p.p_partkey,
           p.p_name,
           p.p_brand,
           p.p_type,
           p.p_retailprice,
           RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
),
SupplierAvailability AS (
    SELECT ps.ps_partkey,
           ps.ps_suppkey,
           ps.ps_availqty,
           PS.ps_supplycost * ps.ps_availqty AS total_supply_value,
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS supply_rank
    FROM partsupp ps
),
OrderSummary AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT n.n_name,
       r.r_name,
       COALESCE(SUM(sa.total_supply_value), 0) AS total_supplier_value,
       COUNT(DISTINCT os.o_orderkey) AS total_orders,
       AVG(CASE WHEN rp.price_rank = 1 THEN rp.p_retailprice END) AS avg_highest_price_part,
       SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count
FROM nation n
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN SupplierAvailability sa ON sa.ps_partkey IN (SELECT p.p_partkey FROM RankedParts rp WHERE rp.price_rank <= 5)
LEFT JOIN OrderSummary os ON os.total_revenue > 5000
JOIN lineitem l ON l.l_partkey IN (SELECT rp.p_partkey FROM RankedParts rp WHERE rp.price_rank = 1)
WHERE n.n_name IS NOT NULL
GROUP BY n.n_name, r.r_name
HAVING COUNT(DISTINCT os.o_orderkey) > 0
ORDER BY total_supplier_value DESC, total_orders ASC;
