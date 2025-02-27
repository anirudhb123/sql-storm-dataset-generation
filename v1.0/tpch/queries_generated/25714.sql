WITH String_Stats AS (
    SELECT 
        p.p_partkey,
        LENGTH(p.p_name) AS name_length,
        LENGTH(p.p_comment) AS comment_length,
        REGEXP_COUNT(p.p_name, '[aeiou]', 1, 'i') AS vowel_count,
        REGEXP_COUNT(p.p_name, '[^aeiou]', 1, 'i') AS consonant_count,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        customer c ON s.s_nationkey = c.c_nationkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_comment
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_comment,
    CONCAT('Length of Name: ', name_length, ', Length of Comment: ', comment_length) AS string_lengths,
    CONCAT('Vowels: ', vowel_count, ', Consonants: ', consonant_count) AS vowel_consonant_stats,
    supplier_count,
    customer_count
FROM 
    String_Stats s
JOIN 
    part p ON p.p_partkey = s.p_partkey
ORDER BY 
    name_length DESC, supplier_count DESC
LIMIT 100;
