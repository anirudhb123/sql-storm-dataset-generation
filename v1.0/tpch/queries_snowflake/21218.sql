WITH RECURSIVE OrderTotals AS (
    SELECT o_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o_orderkey
    HAVING SUM(l_extendedprice * (1 - l_discount)) > 1000
),
HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (
        SELECT AVG(s_acctbal)
        FROM supplier
    )
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
    HAVING COUNT(DISTINCT ps.ps_suppkey) > 0
),
AggregatedData AS (
    SELECT r.r_name, SUM(ot.total) AS total_sales, COUNT(DISTINCT c.c_custkey) AS unique_customers
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN OrderTotals ot ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE ot.o_orderkey = o.o_orderkey)
    GROUP BY r.r_name
)
SELECT pd.p_partkey, pd.p_name, pd.p_retailprice, 
       COALESCE(agg.total_sales, 0) AS total_sales, 
       COALESCE(agg.unique_customers, 0) AS unique_customers,
       hs.s_name AS high_value_supplier
FROM PartDetails pd
LEFT JOIN HighValueSuppliers hs ON pd.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = hs.s_suppkey LIMIT 1)
LEFT JOIN AggregatedData agg ON pd.p_name LIKE '%' || COALESCE(hs.s_name, '') || '%'
WHERE (pd.supplier_count > 1 OR hs.s_name IS NOT NULL)
AND pd.p_retailprice < COALESCE((SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 30), 0)
ORDER BY total_sales DESC, unique_customers ASC;
