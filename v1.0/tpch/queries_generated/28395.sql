WITH SupplierInfo AS (
    SELECT s.s_name, s.s_address, s.nationkey, 
           CONCAT(s.s_name, ' ', s.s_address) AS full_info,
           LENGTH(CONCAT(s.s_name, ' ', s.s_address)) AS info_length,
           REGEXP_REPLACE(s.s_comment, '[^a-zA-Z0-9]', ' ') AS clean_comment
    FROM supplier s
),
PartInfo AS (
    SELECT p.p_name, p.p_brand, p.p_type, 
           UPPER(p.p_comment) AS upper_comment,
           LENGTH(p.p_name) AS name_length,
           p.p_size
    FROM part p
),
CustomerInfo AS (
    SELECT c.c_name, c.c_address, c.c_mktsegment, 
           SUBSTRING(c.c_comment, 1, 30) AS short_comment,
           LENGTH(c.c_address) AS address_length
    FROM customer c
)
SELECT si.s_name, pi.p_name, ci.c_name, 
       si.full_info, pi.upper_comment,
       ci.short_comment, si.info_length,
       pi.name_length, ci.address_length 
FROM SupplierInfo si
JOIN PartInfo pi ON si.nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = 1)
JOIN CustomerInfo ci ON ci.c_mktsegment = 'BUILD'
WHERE si.info_length > 50 
ORDER BY si.s_name, pi.p_name;
