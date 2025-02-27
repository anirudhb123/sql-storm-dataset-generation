WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
),
TotalLineItemSales AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(*) AS num_sales
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '2023-01-01'
    GROUP BY l.l_partkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, p.p_container,
           COALESCE(SUM(ps.ps_availqty), 0) AS total_available
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice, p.p_container
)
SELECT pd.p_name, pd.p_retailprice, pd.total_available,
       COALESCE(tl.total_sales, 0) AS total_sales,
       COALESCE(tl.num_sales, 0) AS num_sales,
       rs.s_name AS top_supplier
FROM PartDetails pd
LEFT JOIN TotalLineItemSales tl ON pd.p_partkey = tl.l_partkey
LEFT JOIN RankedSuppliers rs ON rs.rn = 1 AND rs.s_nationkey = (
    SELECT n.n_nationkey 
    FROM nation n 
    JOIN region r ON n.n_regionkey = r.r_regionkey 
    WHERE r.r_name = 'ASIA'
)
WHERE pd.p_retailprice > 50.00
ORDER BY pd.total_available DESC, total_sales DESC;
