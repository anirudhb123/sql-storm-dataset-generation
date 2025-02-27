WITH SupplierDetails AS (
    SELECT 
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_acctbal,
        s.s_comment,
        (
            SELECT COUNT(DISTINCT ps.partkey) 
            FROM partsupp ps 
            WHERE ps.suppkey = s.s_suppkey
        ) AS parts_count,
        (
            SELECT SUM(l.l_quantity * l.l_extendedprice) 
            FROM lineitem l 
            JOIN orders o ON l.orderkey = o.o_orderkey 
            WHERE l.suppkey = s.s_suppkey 
            AND o.o_orderstatus = 'F' 
            AND l.shipdate >= '2022-01-01'
        ) AS total_revenue
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE LENGTH(s.s_name) > 5 AND s.s_acctbal > 1000
)
SELECT 
    sd.s_name,
    sd.s_address,
    sd.nation_name,
    sd.region_name,
    sd.parts_count,
    sd.total_revenue,
    SUBSTR(sd.s_comment, 1, 50) AS short_comment,
    CONCAT('Supplier in ', sd.region_name, ' - ', sd.nation_name) AS supplier_location
FROM SupplierDetails sd
ORDER BY sd.total_revenue DESC, sd.s_name
LIMIT 10;
