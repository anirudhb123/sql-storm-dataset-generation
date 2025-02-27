WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        LENGTH(s.s_comment) AS comment_length,
        CONCAT(s.s_name, ' - ', n.n_name) AS supplier_info
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        SUBSTRING(p.p_comment, 1, 15) AS short_comment,
        UPPER(p.p_name) AS upper_case_name
    FROM 
        part p
), OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_custkey) AS customer_count,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    sd.s_name,
    sd.nation_name,
    pd.p_name,
    pd.p_type,
    os.total_sales,
    os.customer_count,
    os.avg_quantity,
    sd.comment_length,
    sd.supplier_info
FROM 
    SupplierDetails sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN 
    OrderSummary os ON os.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name LIKE 'Customer%'))
WHERE 
    pd.p_retailprice > 100.00
ORDER BY 
    os.total_sales DESC, 
    sd.comment_length ASC;
