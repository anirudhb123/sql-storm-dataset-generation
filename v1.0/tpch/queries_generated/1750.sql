WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank_in_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    p.p_name,
    p.p_brand,
    s.s_name,
    COALESCE(sd.rank_in_nation, 'Not Applicable') AS supplier_rank_in_nation,
    os.total_sales,
    hp.total_value,
    CASE 
        WHEN hp.total_value IS NOT NULL THEN 'High Value'
        ELSE 'Low Value'
    END AS part_value_category,
    CONCAT(p.p_name, ' - ', ss.nation_name) AS composite_name
FROM 
    part p
LEFT JOIN 
    HighValueParts hp ON p.p_partkey = hp.ps_partkey
LEFT JOIN 
    SupplierDetails sd ON p.p_partkey = sd.s_suppkey
LEFT JOIN 
    OrderSummary os ON os.o_orderkey = p.p_partkey
CROSS JOIN 
    region r
WHERE 
    p.p_retailprice > 50.00 
    AND (r.r_name IS NULL OR r.r_name LIKE 'Africa%')
ORDER BY 
    total_sales DESC NULLS LAST,
    part_value_category;
