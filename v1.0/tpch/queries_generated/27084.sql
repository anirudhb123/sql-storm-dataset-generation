WITH RECURSIVE part_names AS (
    SELECT p_name, LENGTH(p_name) AS name_length
    FROM part
    WHERE p_size > 10
   
    UNION ALL
   
    SELECT CONCAT('Accessory to ', p_name), LENGTH(CONCAT('Accessory to ', p_name))
    FROM part_names
    WHERE name_length < 100
),
supplier_info AS (
    SELECT s_name, s_comment, COUNT(ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.suppkey, s.s_name, s.s_comment
)
SELECT pn.p_name, si.s_name, 
       CASE 
           WHEN LENGTH(si.s_comment) > 100 THEN SUBSTRING(si.s_comment, 1, 100) 
           ELSE si.s_comment 
       END AS truncated_comment,
       si.part_count
FROM part_names pn
JOIN supplier_info si ON pn.name_length % si.part_count = 0
ORDER BY pn.name_length DESC, si.s_name ASC;
