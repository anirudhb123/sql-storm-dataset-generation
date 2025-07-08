
WITH StringProcessing AS (
    SELECT p_partkey, 
           p_name, 
           LENGTH(p_name) AS name_length,
           CASE 
               WHEN p_name LIKE '%brass%' THEN 'Contains Brass'
               ELSE 'Does Not Contain Brass'
           END AS brass_indicator,
           SUBSTRING(p_name, 1, 10) AS name_substring
    FROM part
), AggregatedStrings AS (
    SELECT brass_indicator, 
           AVG(name_length) AS avg_length,
           COUNT(*) AS count_parts,
           LISTAGG(name_substring, ', ') AS concatenated_names
    FROM StringProcessing
    GROUP BY brass_indicator
)
SELECT r.r_name AS region_name, 
       n.n_name AS nation_name, 
       a.brass_indicator, 
       a.avg_length, 
       a.count_parts, 
       a.concatenated_names
FROM region r
JOIN nation n ON n.n_regionkey = r.r_regionkey
JOIN (
    SELECT DISTINCT s.s_nationkey, 
           a.brass_indicator, 
           a.avg_length, 
           a.count_parts, 
           a.concatenated_names
    FROM AggregatedStrings a
    JOIN supplier s ON s.s_nationkey = n.n_nationkey
) a ON a.s_nationkey = n.n_nationkey
ORDER BY region_name, nation_name;
