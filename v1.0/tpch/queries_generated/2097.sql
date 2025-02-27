WITH RankedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) as price_rank
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2022-01-01' AND l.l_shipdate <= '2023-12-31'
),
TotalOrderValue AS (
    SELECT 
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COUNT(ps.ps_partkey) AS supplied_parts
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
)
SELECT 
    r.l_orderkey,
    SUM(r.l_extendedprice) AS total_extended_price,
    COUNT(DISTINCT r.l_partkey) AS unique_parts_count,
    t.total_value,
    s.s_name,
    s.supplied_parts,
    n.n_name AS supplier_nation
FROM 
    RankedLineItems r
JOIN 
    TotalOrderValue t ON r.l_orderkey = t.o_orderkey
JOIN 
    SupplierDetails s ON r.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    r.price_rank <= 5
GROUP BY 
    r.l_orderkey, t.total_value, s.s_name, s.supplied_parts, n.n_name
ORDER BY 
    total_extended_price DESC
LIMIT 10
UNION ALL
SELECT 
    NULL AS l_orderkey,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS total_extended_price,
    COUNT(DISTINCT l.l_partkey) AS unique_parts_count,
    NULL,
    NULL,
    NULL,
    'Average' AS supplier_nation
FROM 
    lineitem l
WHERE 
    l.l_shipdate >= '2022-01-01' AND l.l_shipdate <= '2023-12-31';
