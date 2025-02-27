WITH RecursiveRegion AS (
    SELECT r_regionkey, r_name, r_comment, 1 AS region_level
    FROM region
    WHERE r_name IS NOT NULL

    UNION ALL

    SELECT r_regionkey, r_name, r_comment, region_level + 1
    FROM region r
    JOIN RecursiveRegion rr ON r.r_regionkey = rr.r_regionkey
    WHERE rr.region_level < 3
),
AggregatedSuppliers AS (
    SELECT s.n_nationkey, COUNT(s.s_suppkey) AS total_suppliers, SUM(s.s_acctbal) AS total_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.n_nationkey
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY o.o_orderkey, o.o_custkey
)
SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_retailprice,
       COALESCE(a.total_suppliers, 0) AS supplier_count,
       COALESCE(a.total_acctbal, 0.00) AS total_account_balance,
       CASE WHEN r.r_name IS NULL THEN 'Unknown Region'
            ELSE r.r_name 
       END AS region_name,
       ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank_within_type
FROM part p
LEFT JOIN AggregatedSuppliers a ON p.p_partkey = a.n_nationkey
LEFT JOIN RecursiveRegion r ON a.n_nationkey = r.r_regionkey
WHERE p.p_size IN (SELECT DISTINCT CASE 
                                       WHEN p_type LIKE '%extra%' THEN p_size 
                                       ELSE NULL 
                                   END 
                   FROM part)
AND p.p_retailprice BETWEEN (SELECT AVG(ps_supplycost) FROM partsupp) 
                        AND (SELECT MAX(ps_supplycost) FROM partsupp)
ORDER BY supplier_count DESC, total_account_balance ASC
LIMIT 100;
