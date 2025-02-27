WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_container,
        p.p_retailprice,
        SUBSTRING_INDEX(p.p_comment, ' ', 5) AS short_comment,
        LENGTH(REPLACE(p.p_name, ' ', '')) AS name_length,
        CONCAT(p.p_brand, '-', p.p_container) AS brand_container
    FROM 
        part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal > 100000 THEN 'High Value'
            WHEN s.s_acctbal BETWEEN 50000 AND 100000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS acctbal_category
    FROM 
        supplier s
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        c.c_name,
        o.o_orderstatus,
        o.o_totalprice,
        DATE_FORMAT(o.o_orderdate, '%Y-%m-%d') AS formatted_orderdate,
        o.o_comment,
        COUNT(l.l_orderkey) AS item_count,
        SUM(l.l_extendedprice) AS total_lineitem_price
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_name, o.o_orderstatus, o.o_totalprice, o.o_orderdate, o.o_comment
)
SELECT 
    pd.p_partkey,
    pd.p_name,
    pd.p_brand,
    pd.brand_container,
    sd.s_name AS supplier_name,
    sd.acctbal_category,
    co.o_orderkey,
    co.c_name AS customer_name,
    co.item_count,
    co.total_lineitem_price,
    co.formatted_orderdate,
    pd.short_comment,
    pd.name_length
FROM 
    PartDetails pd
JOIN 
    partsupp ps ON pd.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    CustomerOrders co ON co.o_orderkey = ps.ps_partkey
WHERE 
    pd.p_retailprice > 50.00
    AND sd.acctbal_category = 'High Value'
ORDER BY 
    co.total_lineitem_price DESC, 
    pd.p_name ASC;
