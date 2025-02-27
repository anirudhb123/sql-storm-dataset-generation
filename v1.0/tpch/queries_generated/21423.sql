WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F') AND o.o_totalprice IS NOT NULL
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           CASE 
               WHEN s.s_acctbal IS NULL THEN 'Unknown Balance'
               WHEN s.s_acctbal < 0 THEN 'Overdrawn'
               ELSE 'In Good Standing' 
           END AS status
    FROM supplier s
),
PainterParts AS (
    SELECT p.p_partkey, p.p_name
    FROM part p
    WHERE p.p_mfgr LIKE '%Painter%'
),
JoinDetails AS (
    SELECT p.p_partkey, pd.s_suppkey, pd.s_name, pd.s_acctbal, pd.status,
           COALESCE(l.l_discount, 0) AS discount_applied
    FROM PainterParts p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN SupplierDetails pd ON ps.ps_suppkey = pd.s_suppkey
    LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0 AND pd.status <> 'Unknown Balance'
)
SELECT jd.p_partkey, jd.s_name, jd.s_acctbal, jd.status,
       SUM(jd.discount_applied) OVER (PARTITION BY jd.s_suppkey ORDER BY jd.s_acctbal DESC) AS cumulative_discount,
       COUNT(*) OVER (PARTITION BY jd.p_partkey) AS order_count,
       STRING_AGG(DISTINCT COALESCE(jd.status, 'Not Specified'), ', ') FILTER (WHERE jd.status IS NOT NULL) AS supplier_status,
       MAX(CASE WHEN o.rn <= 10 THEN o.o_totalprice ELSE NULL END) AS top_order_price
FROM JoinDetails jd
LEFT JOIN RankedOrders o ON o.o_orderkey = jd.s_suppkey
WHERE jd.s_acctbal IS NOT NULL OR jd.status IS NOT NULL
GROUP BY jd.p_partkey, jd.s_name, jd.s_acctbal, jd.status
HAVING SUM(jd.discount_applied) > 0 OR COUNT(*) > 5
ORDER BY jd.p_partkey, jd.s_name;
