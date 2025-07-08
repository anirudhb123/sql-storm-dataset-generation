WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_phone, 
        n.n_name AS nation_name, 
        REPLACE(s.s_address, ',', '') AS clean_address,
        LENGTH(REPLACE(s.s_comment, ' ', '')) AS non_space_comment_length,
        TRIM(UPPER(SUBSTRING(s.s_comment, 1, 30))) AS truncated_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
CombinedData AS (
    SELECT 
        sd.s_suppkey, 
        sd.s_name, 
        os.o_orderkey, 
        os.total_revenue, 
        os.unique_parts_count, 
        sd.nation_name,
        sd.clean_address,
        sd.non_space_comment_length,
        sd.truncated_comment
    FROM SupplierDetails sd
    JOIN partsupp ps ON sd.s_suppkey = ps.ps_suppkey
    JOIN OrderSummary os ON ps.ps_partkey = (
        SELECT l.l_partkey 
        FROM lineitem l 
        WHERE l.l_orderkey = os.o_orderkey 
        LIMIT 1
    )
)
SELECT 
    nation_name, 
    AVG(total_revenue) AS avg_revenue, 
    SUM(unique_parts_count) AS total_unique_parts,
    MAX(non_space_comment_length) AS max_comment_length,
    COUNT(DISTINCT clean_address) AS unique_addresses
FROM CombinedData
GROUP BY nation_name
ORDER BY avg_revenue DESC, total_unique_parts DESC;
