
WITH RECURSIVE SupplierBalance AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, 0 AS tier
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal / 2.0, s.s_comment, sb.tier + 1
    FROM supplier s
    JOIN SupplierBalance sb ON s.s_suppkey = sb.s_suppkey
    WHERE sb.s_acctbal > 10 AND sb.tier < 5
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as price_rank,
           CASE
               WHEN o.o_orderstatus = 'F' THEN 'Finalized'
               WHEN o.o_orderstatus = 'P' THEN 'Pending'
               ELSE 'Unknown'
           END AS order_status_desc
    FROM orders o
    WHERE o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1998-10-01'
),
AvgTotalPrice AS (
    SELECT AVG(o_totalprice) AS avg_price
    FROM FilteredOrders
)
SELECT
    p.p_partkey,
    p.p_name,
    p.p_brand,
    SUM(COALESCE(l.l_discount * l.l_extendedprice, 0)) AS total_discounted_price,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    MAX(COALESCE(r.r_name, 'No Region')) AS region_name,
    NULLIF(SUM(s.s_acctbal), 0) AS total_supplier_balance
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN partsupp ps ON ps.ps_partkey = p.p_partkey
LEFT JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN nation n ON n.n_nationkey = s.s_nationkey
LEFT JOIN region r ON r.r_regionkey = n.n_regionkey
WHERE p.p_retailprice > (SELECT avg_price FROM AvgTotalPrice)
    AND (l.l_returnflag = 'N' OR l.l_returnflag IS NULL)
GROUP BY p.p_partkey, p.p_name, p.p_brand
HAVING COUNT(DISTINCT l.l_orderkey) > 5
   OR (SUM(l.l_quantity) > 100 AND SUM(l.l_extendedprice) < 10000)
ORDER BY total_discounted_price DESC, order_count ASC;
