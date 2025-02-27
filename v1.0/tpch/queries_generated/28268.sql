WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        CONCAT('Manufacturer: ', p.p_mfgr, ', Brand: ', p.p_brand, ', Type: ', p.p_type) AS formatted_description
    FROM 
        part p
), SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        s.s_phone,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT 
    pd.formatted_description,
    si.s_name,
    si.nation_name,
    co.total_quantity,
    co.total_value
FROM 
    PartDetails pd
JOIN 
    partsupp ps ON pd.p_partkey = ps.ps_partkey
JOIN 
    SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
JOIN 
    CustomerOrders co ON co.total_quantity > 100
WHERE 
    pd.p_retailprice > 20.00
ORDER BY 
    co.total_value DESC, pd.p_name ASC
LIMIT 50;
