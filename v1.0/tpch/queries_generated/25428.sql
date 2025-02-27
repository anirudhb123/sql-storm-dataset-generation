WITH SupplierDetails AS (
    SELECT 
        s.s_name AS supplier_name, 
        s.s_nationkey,
        s.s_acctbal AS account_balance,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name AS part_name, 
        p.p_brand, 
        SUBSTRING(p.p_comment, 1, 15) AS short_comment,
        ps.ps_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
),
CombinedData AS (
    SELECT 
        sd.supplier_name, 
        pd.part_name, 
        pd.p_brand, 
        pd.short_comment, 
        sd.account_balance, 
        sd.nation_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        SupplierDetails sd
    JOIN 
        lineitem l ON sd.s_nationkey = (
            SELECT n.n_nationkey 
            FROM nation n 
            WHERE n.n_name = sd.nation_name
        )
    JOIN 
        PartDetails pd ON l.l_partkey = pd.p_partkey
    GROUP BY 
        sd.supplier_name, pd.part_name, pd.p_brand, pd.short_comment, sd.account_balance, sd.nation_name
)
SELECT 
    supplier_name, 
    part_name, 
    p_brand, 
    short_comment, 
    account_balance, 
    nation_name, 
    total_sales
FROM 
    CombinedData
WHERE 
    total_sales > 10000
ORDER BY 
    total_sales DESC, 
    supplier_name ASC;
