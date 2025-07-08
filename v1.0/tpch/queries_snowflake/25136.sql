WITH SupplierDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        s.s_address AS supplier_address,
        n.n_name AS nation_name,
        SUBSTRING(s.s_comment, 1, 50) AS short_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PartDetails AS (
    SELECT 
        p.p_partkey AS part_key,
        p.p_name AS part_name,
        p.p_brand AS part_brand,
        p.p_container AS part_container,
        LPAD(CAST(p.p_size AS CHAR), 3, '0') AS formatted_size,
        ROUND(p.p_retailprice, 2) AS formatted_price,
        CONCAT(LEFT(p.p_comment, 20), '...') AS short_comment
    FROM 
        part p
),
OrderSummary AS (
    SELECT 
        o.o_orderkey AS order_key,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    sd.supplier_name,
    sd.supplier_address,
    sd.nation_name,
    pd.part_name,
    pd.formatted_size,
    pd.formatted_price,
    os.total_revenue,
    LEFT(sd.short_comment, 25) AS supplier_comment,
    LEFT(pd.short_comment, 25) AS part_comment
FROM 
    SupplierDetails sd
JOIN 
    PartDetails pd ON pd.part_key IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < 100.00)
JOIN 
    OrderSummary os ON os.order_key IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31')
WHERE 
    sd.nation_name = 'Germany'
ORDER BY 
    os.total_revenue DESC, sd.supplier_name;