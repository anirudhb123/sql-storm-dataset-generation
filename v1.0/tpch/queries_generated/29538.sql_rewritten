WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        r.r_name AS region,
        REPLACE(s.s_comment, 'good', 'excellent') AS adjusted_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        LENGTH(s.s_address) > 30
), 
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CONCAT(p.p_brand, ' ', p.p_type) AS full_description,
        SUBSTR(p.p_comment, 1, POSITION('|' IN p.p_comment || '|') - 1) AS short_comment
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 50
),
OrderSummaries AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate > cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    sd.s_name,
    sd.region,
    pd.full_description,
    os.total_revenue,
    os.unique_customers,
    sd.adjusted_comment
FROM 
    SupplierDetails sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN 
    OrderSummaries os ON os.o_orderkey = (SELECT o.o_orderkey FROM orders o JOIN lineitem l ON o.o_orderkey = l.l_orderkey WHERE l.l_suppkey = sd.s_suppkey LIMIT 1)
WHERE 
    LOWER(sd.region) LIKE '%north%'
ORDER BY 
    os.total_revenue DESC, 
    sd.s_name;