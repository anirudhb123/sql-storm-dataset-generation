WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        CONCAT(s.s_address, ', ', n.n_name) AS full_address,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
FormattedParts AS (
    SELECT 
        p.p_partkey, 
        UPPER(p.p_name) AS upper_name, 
        REPLACE(p.p_comment, 'bad', 'good') AS modified_comment
    FROM 
        part p
    WHERE 
        LENGTH(p.p_name) > 10
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice) AS total_extended_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice
)
SELECT 
    sd.s_name AS supplier_name,
    sd.full_address,
    fp.upper_name AS part_name,
    od.o_orderdate,
    od.total_extended_price,
    od.lineitem_count,
    CASE 
        WHEN od.total_extended_price > 1000 THEN 'High Value' 
        WHEN od.total_extended_price BETWEEN 500 AND 1000 THEN 'Medium Value' 
        ELSE 'Low Value' 
    END AS order_value_category
FROM 
    SupplierDetails sd
JOIN 
    FormattedParts fp ON sd.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = fp.p_partkey LIMIT 1)
JOIN 
    OrderDetails od ON fp.p_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = od.o_orderkey LIMIT 1)
WHERE 
    sd.s_acctbal > 5000
ORDER BY 
    od.o_orderdate DESC, order_value_category;
