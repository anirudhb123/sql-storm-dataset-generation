WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        LENGTH(s.s_name) AS name_length,
        LENGTH(s.s_address) AS address_length,
        REGEXP_COUNT(s.s_comment, '[aeiou]') AS vowel_count,
        REGEXP_REPLACE(s.s_comment, '[^a-zA-Z ]', '') AS cleaned_comment
    FROM supplier s
), PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        p.p_type,
        p.p_brand,
        p.p_container,
        LENGTH(p.p_name) AS name_length,
        LENGTH(p.p_type) AS type_length,
        LENGTH(p.p_brand) AS brand_length,
        REGEXP_COUNT(p.p_comment, '[aeiou]') AS vowel_count
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
), CombinedData AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.name_length AS supplier_name_length,
        sd.vowel_count AS supplier_vowel_count,
        ps.ps_partkey,
        ps.p_name,
        ps.name_length AS part_name_length,
        ps.vowel_count AS part_vowel_count
    FROM SupplierDetails sd
    JOIN PartSupplier ps ON sd.s_suppkey = ps.ps_suppkey
)
SELECT 
    s.supp_key,
    s.s_name,
    s.supplier_name_length,
    s.p_partkey,
    s.p_name,
    s.part_name_length,
    LEAST(s.supplier_name_length, s.part_name_length) AS min_length,
    GREATEST(s.supplier_name_length, s.part_name_length) AS max_length,
    (s.supplier_vowel_count + s.part_vowel_count) AS total_vowel_count
FROM CombinedData s
WHERE s.supplier_name_length > 10 
ORDER BY total_vowel_count DESC, max_length ASC;
