WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        s.s_comment,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
EnhancedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_type,
        p.p_brand,
        p.p_size,
        p.p_retailprice,
        CONCAT(p.p_name, ' - Type: ', p.p_type, ' - Brand: ', p.p_brand) AS detailed_description
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
TopLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
    HAVING 
        SUM(l.l_quantity) > 10
)
SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT cs.c_custkey) AS customer_count,
    SUM(TLI.total_price) AS total_sales,
    STRING_AGG(DISTINCT EP.detailed_description, ', ') AS unique_part_descriptions
FROM 
    nation n
JOIN 
    customer cs ON n.n_nationkey = cs.c_nationkey
JOIN 
    orders o ON cs.c_custkey = o.o_custkey
JOIN 
    TopLineItems TLI ON o.o_orderkey = TLI.l_orderkey
JOIN 
    EnhancedParts EP ON EP.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM RankedSuppliers s WHERE s.rank <= 5))
WHERE 
    o.o_orderdate >= DATE '2023-01-01'
GROUP BY 
    n.n_name
ORDER BY 
    total_sales DESC;
