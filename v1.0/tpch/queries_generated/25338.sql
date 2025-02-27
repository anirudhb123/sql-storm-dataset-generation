WITH RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_mfgr, 
           p.p_brand, 
           p.p_type, 
           p.p_size, 
           p.p_container, 
           p.p_retailprice, 
           p.p_comment,
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) as part_rank
    FROM part p
),
FilteredSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_address, 
           n.n_name AS supplier_nation, 
           s.s_phone, 
           s.s_acctbal, 
           s.s_comment 
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
TopPartSuppliers AS (
    SELECT fps.s_suppkey, 
           fps.s_name, 
           fps.s_address, 
           fp.p_partkey, 
           fp.p_name, 
           fps.s_nationkey 
    FROM FilteredSuppliers fps
    JOIN partsupp ps ON fps.s_suppkey = ps.ps_suppkey
    JOIN RankedParts fp ON ps.ps_partkey = fp.p_partkey
    WHERE fp.part_rank <= 5
)
SELECT COUNT(DISTINCT tps.s_suppkey) AS total_suppliers, 
       SUM(fp.p_retailprice) AS total_retail_value, 
       STRING_AGG(CONCAT(fp.p_name, ' from ', tps.s_name), '; ') AS supplier_part_list
FROM TopPartSuppliers tps
JOIN part fp ON tps.p_partkey = fp.p_partkey
GROUP BY tps.s_nationkey
ORDER BY total_suppliers DESC;
