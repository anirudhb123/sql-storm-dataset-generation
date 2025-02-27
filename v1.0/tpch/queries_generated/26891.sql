WITH RecursiveSupplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.n_nationkey, 
           SUBSTRING(s.s_comment, 1, 25) AS short_comment
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT ps.ps_suppkey, s.s_name, s.s_address, s.n_nationkey, 
           CONCAT(r.r_name, ' | ', s.s_name, ' | ', SUBSTRING(s.s_comment, 1, 25)) 
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN region r ON s.n_nationkey = r.r_regionkey
    WHERE ps.ps_availqty < 100
)

SELECT r.r_name AS region, 
       COUNT(DISTINCT ss.s_suppkey) AS supplier_count,
       STRING_AGG(CONCAT(ss.s_name, ': ', ss.short_comment), '; ') AS supplier_details
FROM RecursiveSupplier ss
JOIN region r ON ss.n_nationkey = r.r_regionkey
GROUP BY r.r_name
ORDER BY r.r_name;
