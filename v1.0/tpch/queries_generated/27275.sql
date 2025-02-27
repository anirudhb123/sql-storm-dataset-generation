WITH SupplierDetails AS (
    SELECT 
        s.s_name,
        s.s_address,
        n.n_name AS nation,
        r.r_name AS region,
        s.s_acctbal,
        s.s_comment,
        CONCAT(s.s_name, ' located in ', s.s_address, ', from ', n.n_name, ' of ', r.r_name, ' region. Remark: ', s.s_comment) AS supplier_info
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
PartDetails AS (
    SELECT 
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        CONCAT('Part: ', p.p_name, ', Brand: ', p.p_brand, ', Type: ', p.p_type, ', Container: ', p.p_container, ', Price: $', FORMAT(p.p_retailprice, 2), '. Comment: ', p.p_comment) AS part_info
    FROM part p
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(*) AS item_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    sd.supplier_info,
    pd.part_info,
    ls.total_value,
    ls.item_count
FROM SupplierDetails sd
JOIN PartDetails pd ON pd.p_comment LIKE CONCAT('%', SUBSTRING(sd.supplier_info FROM 1 FOR 5), '%')
JOIN LineItemStats ls ON EXISTS (
    SELECT 1 FROM lineitem l 
    JOIN orders o ON l.l_orderkey = o.o_orderkey 
    WHERE 
        o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name = sd.s_name LIMIT 1)
        AND l.l_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_name LIKE CONCAT('%', pd.p_name, '%') LIMIT 1)
)
ORDER BY sd.supplier_info, ls.total_value DESC;
