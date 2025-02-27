WITH RecursiveCTE AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_supplycost,
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_availqty > 0
    UNION ALL
    SELECT 
        r.p_partkey,
        r.p_name,
        r.p_retailprice,
        r.ps_supplycost,
        r.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY r.p_partkey ORDER BY r.ps_supplycost DESC) AS rn
    FROM 
        RecursiveCTE r
    WHERE 
        EXISTS (SELECT 1 FROM supplier s WHERE s.s_suppkey = r.ps_supplycost)
        AND r.ps_availqty < 100
),
EligibleSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) OR s.s_comment LIKE '%loyal%'
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_discount) as total_discount,
        SUM(l.l_extendedprice * (1 - l.l_discount)) as total_price,
        COUNT(DISTINCT l.l_orderkey) as order_count,
        DENSE_RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    p.p_partkey,
    p.p_name,
    ps.ps_supplycost,
    s.s_name AS supplier_name,
    COALESCE(e.part_count, 0) AS eligible_part_count,
    o.total_price,
    ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.total_discount DESC) AS discount_rank
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    EligibleSuppliers e ON ps.ps_suppkey = e.s_suppkey
INNER JOIN 
    OrderStats o ON o.o_orderstatus = 'F'
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size BETWEEN 10 AND 30)
    AND (s_name IS NOT NULL OR s_name IS NULL)  -- Testing NULL logic
ORDER BY 
    info_id DESC, o.total_price DESC;
