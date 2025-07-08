WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(NULLIF(p.p_comment, ''), 'No comment provided') AS p_comment,
        RANK() OVER (PARTITION BY SUBSTRING(p.p_name, 1, 1) ORDER BY p.p_retailprice DESC) AS rank_price
    FROM 
        part p
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        CASE 
            WHEN LENGTH(s.s_comment) > 100 THEN CONCAT(SUBSTRING(s.s_comment, 1, 96), '...')
            ELSE s.s_comment 
        END AS s_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
AggregatedOrders AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS line_count,
        SUM(l.l_extendedprice) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_comment,
    fs.s_suppkey,
    fs.s_name,
    ao.o_orderkey,
    ao.line_count,
    ao.total_price
FROM 
    RankedParts rp
JOIN 
    FilteredSuppliers fs ON rp.p_partkey % 10 = fs.s_suppkey % 10
JOIN 
    AggregatedOrders ao ON rp.p_partkey % 100 = ao.o_orderkey % 100
WHERE 
    rp.rank_price <= 10 
ORDER BY 
    ao.total_price DESC, 
    fs.s_name ASC
LIMIT 50;
