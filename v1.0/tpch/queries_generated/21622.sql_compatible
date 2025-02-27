
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
AggregateLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN CURRENT_DATE - INTERVAL '90 DAY' AND CURRENT_DATE
    GROUP BY 
        l.l_orderkey
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        n.n_regionkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, n.n_regionkey
    HAVING 
        COUNT(o.o_orderkey) > 5
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_brand,
        p.p_container,
        p.p_retailprice,
        COALESCE(NULLIF(p.p_retailprice, 0), NULL) AS safe_retailprice
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 500)
        OR p.p_brand LIKE 'Brand%H'
),
Combination AS (
    SELECT 
        cr.c_custkey,
        cr.n_regionkey,
        COUNT(DISTINCT ps.ps_partkey) AS unique_part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        CustomerRegion cr
    LEFT JOIN 
        partsupp ps ON cr.c_custkey = (SELECT c.c_custkey FROM customer c WHERE cr.n_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = c.c_nationkey) LIMIT 1)
    GROUP BY 
        cr.c_custkey, cr.n_regionkey
)
SELECT 
    fs.p_container,
    fs.p_brand,
    COALESCE(rs.s_name, 'Unknown Supplier') AS supplier_name,
    COUNT(DISTINCT li.l_orderkey) AS order_count,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS sum_extended_price,
    AVG(li.l_discount) AS average_discount,
    SUM(CASE WHEN li.l_returnflag = 'R' THEN li.l_quantity ELSE 0 END) AS total_returned_quantity,
    COUNT(DISTINCT CASE WHEN li.l_tax BETWEEN 0.05 AND 0.10 THEN li.l_linenumber END) AS taxed_line_items
FROM 
    FilteredParts fs
LEFT JOIN 
    partsupp ps ON fs.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey AND rs.rank = 1
LEFT JOIN 
    lineitem li ON ps.ps_partkey = li.l_partkey
WHERE 
    ((rs.s_acctbal IS NOT NULL AND rs.s_acctbal > 1000)
     OR (rs.s_acctbal IS NULL AND fs.safe_retailprice < 30))
    AND li.l_commitdate < li.l_shipdate
GROUP BY 
    fs.p_container, fs.p_brand, rs.s_name
HAVING 
    SUM(li.l_extendedprice * (1 - li.l_discount)) > 1000
ORDER BY 
    fs.p_container, sum_extended_price DESC;
