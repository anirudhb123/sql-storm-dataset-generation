WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, n.n_name AS nation_name, 
           RTRIM(LTRIM(s.s_comment)) AS trimmed_comment,
           REGEXP_REPLACE(s.s_comment, '[^a-zA-Z0-9 ]', '') AS clean_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), 
PartInfo AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, 
           CONCAT(p.p_name, ' - ', p.p_brand) AS full_description,
           LEFT(p.p_comment, 20) AS short_comment
    FROM part p
), 
LineItemAnalytics AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_partkey) AS unique_parts,
           STRING_AGG(DISTINCT p.full_description, '; ') AS all_parts
    FROM lineitem l
    JOIN PartInfo p ON l.l_partkey = p.p_partkey
    GROUP BY l.l_orderkey
)
SELECT si.s_name, si.nation_name, si.trimmed_comment, 
       pi.p_name, li.total_revenue, li.unique_parts, li.all_parts
FROM SupplierInfo si
JOIN partsupp ps ON si.s_suppkey = ps.ps_suppkey
JOIN PartInfo pi ON ps.ps_partkey = pi.p_partkey
JOIN LineItemAnalytics li ON pi.p_partkey = li.l_orderkey
WHERE si.trimmed_comment LIKE '%quality%'
ORDER BY li.total_revenue DESC, si.nation_name;
