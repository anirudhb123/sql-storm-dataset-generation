WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        CONCAT(s.s_name, ' from ', n.n_name) AS full_name,
        LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_comment,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_available_quantity
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_comment
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    pd.p_partkey,
    pd.p_name,
    pd.p_brand,
    sd.full_name AS supplier_info,
    cd.c_name AS customer_name,
    cd.order_count,
    cd.total_spent,
    (SELECT COUNT(*) FROM region) AS total_regions,
    sd.comment_length
FROM 
    PartDetails pd
LEFT JOIN 
    SupplierDetails sd ON pd.supplier_count > 2
LEFT JOIN 
    CustomerOrders cd ON cd.total_spent > 10000
WHERE 
    pd.total_available_quantity > 50
ORDER BY 
    pd.p_partkey, cd.last_order_date DESC;
