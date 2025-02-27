WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
StringProcessedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        CONCAT('Brand: ', p.p_brand, ', Type: ', p.p_type) AS processed_info,
        LENGTH(LOWER(p.p_comment)) AS comment_length
    FROM 
        part p
    WHERE 
        LENGTH(p.p_name) > 10
),
CustOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS num_orders, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)

SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT n.n_nationkey) AS total_nations,
    SUM(co.total_spent) AS total_customer_spending,
    AVG(sp.comment_length) AS avg_part_comment_length
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey
JOIN 
    CustOrders co ON rs.s_suppkey = co.c_custkey
JOIN 
    StringProcessedParts sp ON sp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = rs.s_suppkey)
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT rs.s_suppkey) > 5
ORDER BY 
    total_customer_spending DESC;
