WITH SupplierDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        s.s_address AS supplier_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_acctbal AS supplier_account_balance,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.s_address, n.n_name, r.r_name, s.s_acctbal
),
PartDetails AS (
    SELECT 
        p.p_name AS part_name,
        p.p_size AS part_size,
        p.p_brand AS part_brand,
        p.p_retailprice AS part_retail_price,
        p.p_comment AS part_comment,
        ps.ps_supplycost AS supply_cost,
        ps.ps_availqty AS available_quantity,
        CONCAT(p.p_name, ' (', p.p_brand, ') - ', p.p_comment) AS part_description
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    sd.supplier_name,
    sd.supplier_address,
    sd.nation_name,
    sd.region_name,
    sd.supplier_account_balance,
    sd.total_parts_supplied,
    pd.part_name,
    pd.part_size,
    pd.part_brand,
    pd.part_retail_price,
    pd.part_description
FROM 
    SupplierDetails sd
JOIN 
    PartDetails pd ON sd.total_parts_supplied > 0
ORDER BY 
    sd.supplier_account_balance DESC, 
    pd.part_retail_price ASC;
