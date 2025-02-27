WITH SupplierParts AS (
    SELECT s.s_suppkey,
           s.s_name,
           p.p_partkey,
           p.p_name,
           p.p_brand,
           p.p_retailprice,
           ps.ps_availqty,
           ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
TotalSales AS (
    SELECT l.l_partkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_partkey
),
RankedSuppliers AS (
    SELECT sp.s_suppkey,
           sp.s_name,
           sp.p_partkey,
           sp.p_name,
           sp.p_brand,
           sp.p_retailprice,
           sp.ps_availqty,
           sp.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY sp.p_partkey ORDER BY sp.ps_supplycost ASC) AS supplier_rank,
           COALESCE(ts.total_revenue, 0) AS total_revenue
    FROM SupplierParts sp
    LEFT JOIN TotalSales ts ON sp.p_partkey = ts.l_partkey
)
SELECT r.n_name AS nation_name,
       COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
       AVG(rs.total_revenue) AS avg_revenue,
       MAX(rs.p_retailprice) AS max_retail_price,
       STRING_AGG(CONCAT(rs.p_name, ' (Rank: ', rs.supplier_rank, ')'), ', ') AS supplier_details
FROM rankedSuppliers rs
JOIN supplier s ON rs.s_suppkey = s.s_suppkey
JOIN nation r ON s.s_nationkey = r.n_nationkey
WHERE rs.supplier_rank = 1 
AND rs.ps_availqty > 10
GROUP BY r.n_name
ORDER BY supplier_count DESC, avg_revenue DESC;
