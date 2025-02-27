WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        CONCAT(p.p_name, ' (', p.p_brand, ') - ', p.p_comment) AS full_description
    FROM part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUBSTRING(s.s_address, 1, 20) || '...' AS short_address,
        n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
HighValueSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    GROUP BY l.l_orderkey
    HAVING total_sales > 1000
)
SELECT 
    pd.full_description,
    sd.s_name,
    sd.short_address,
    sd.nation_name,
    hvs.total_sales
FROM PartDetails pd
JOIN partsupp ps ON pd.p_partkey = ps.ps_partkey
JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN HighValueSales hvs ON ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = hvs.l_orderkey)
ORDER BY hvs.total_sales DESC, pd.p_name;
