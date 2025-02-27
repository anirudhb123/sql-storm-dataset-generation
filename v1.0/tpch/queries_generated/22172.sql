WITH RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_price,
           SUM(ps.ps_availqty) OVER (PARTITION BY p.p_partkey) AS total_supplied_qty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
NationalCustomerSpend AS (
    SELECT c.c_nationkey, SUM(o.o_totalprice) AS total_spend
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY c.c_nationkey
),
FilteredNation AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE n.n_nationkey IN (SELECT DISTINCT c_nationkey FROM customer WHERE c_acctbal > (SELECT AVG(c_acctbal) FROM customer))
)
SELECT p.p_brand, 
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS total_revenue,
       AVG(CASE WHEN lp.l_returnflag = 'R' THEN lp.l_quantity ELSE NULL END) AS avg_returned_quantity,
       (SELECT MAX(total_spend) FROM NationalCustomerSpend) AS max_nation_spend,
       ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(lp.l_extendedprice) DESC) AS brand_rank
FROM RankedParts rp
LEFT JOIN lineitem lp ON rp.p_partkey = lp.l_partkey
LEFT JOIN customer c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = lp.l_orderkey AND o.o_orderstatus != 'N')
JOIN FilteredNation fn ON c.c_nationkey = fn.n_nationkey
WHERE rp.rank_price <= 5 AND rp.total_supplied_qty IS NOT NULL
GROUP BY p.p_brand
HAVING COUNT(DISTINCT c.c_custkey) > 10 OR (SELECT COUNT(*) FROM FilteredNation) > 2
ORDER BY total_revenue DESC, brand_rank;
