WITH StringAggregates AS (
    SELECT 
        p.p_partkey,
        UPPER(p.p_name) AS upper_name,
        LOWER(p.p_comment) AS lower_comment,
        CONCAT(p.p_name, ' - ', p.p_comment) AS combined_string,
        LENGTH(p.p_name) AS name_length,
        LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
), 
SupplierData AS (
    SELECT 
        s.s_suppkey,
        REPLACE(s.s_name, 'Supplier', '') AS clean_name,
        SUBSTRING_INDEX(s.s_address, ',', 1) AS city,
        s.s_phone,
        s.s_acctbal
    FROM 
        supplier s
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS lineitem_count
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_name
)
SELECT 
    sa.upper_name, 
    sa.lower_comment,
    sa.combined_string,
    sa.name_length,
    sa.comment_length,
    sd.clean_name,
    sd.city,
    sd.s_phone,
    od.c_name AS customer_name,
    od.total_revenue,
    od.lineitem_count
FROM 
    StringAggregates sa
JOIN 
    SupplierData sd ON sa.p_partkey % 10 = sd.s_suppkey % 10
JOIN 
    OrderDetails od ON sa.p_partkey % 5 = od.o_orderkey % 5
WHERE 
    sa.name_length > 10 AND sd.acctbal > 5000
ORDER BY 
    od.total_revenue DESC, sa.combined_string ASC;
