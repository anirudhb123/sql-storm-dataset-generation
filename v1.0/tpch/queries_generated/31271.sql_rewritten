WITH RECURSIVE SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, level + 1
    FROM supplier s
    INNER JOIN SupplierCTE cte ON s.s_nationkey = cte.s_nationkey
    WHERE s.s_acctbal BETWEEN cte.s_acctbal * 0.5 AND cte.s_acctbal * 1.5 AND level < 3
),
RegionSales AS (
    SELECT n.n_regionkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE l.l_shipdate >= DATE '1995-01-01'
    GROUP BY n.n_regionkey
),
SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_brand, p.p_type, SUM(ps.ps_availqty) AS total_avail
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey, p.p_brand, p.p_type
),
RankedSales AS (
    SELECT r.r_name, rs.total_sales,
           RANK() OVER (PARTITION BY r.r_name ORDER BY rs.total_sales DESC) AS sales_rank
    FROM region r
    JOIN RegionSales rs ON r.r_regionkey = rs.n_regionkey
)
SELECT DISTINCT sp.p_brand, 
                sp.p_type,
                COALESCE(SUM(sp.total_avail), 0) AS total_available,
                COALESCE(AVG(ss.s_acctbal), 0) AS avg_supplier_balance,
                r_sales.r_name, 
                r_sales.sales_rank
FROM SupplierParts sp
LEFT OUTER JOIN SupplierCTE ss ON sp.ps_suppkey = ss.s_suppkey
JOIN RankedSales r_sales ON sp.p_brand = r_sales.r_name
WHERE sp.total_avail > 0 AND 
      r_sales.sales_rank < 3
GROUP BY sp.p_brand, sp.p_type, r_sales.r_name, r_sales.sales_rank
HAVING COALESCE(SUM(sp.total_avail), 0) > 1000 OR COUNT(ss.s_suppkey) > 5
ORDER BY r_sales.sales_rank, sp.p_brand;