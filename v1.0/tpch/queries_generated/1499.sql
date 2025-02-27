WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
PartSupplierCount AS (
    SELECT 
        ps.ps_partkey,
        COUNT(ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        COUNT(ps.ps_suppkey) > 3
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    ps.s_name,
    COALESCE(o.total_value, 0) AS order_value,
    COALESCE(sr.rank, 0) AS supplier_rank,
    pc.supplier_count
FROM 
    part p
LEFT JOIN 
    PartSupplierCount pc ON p.p_partkey = pc.ps_partkey
LEFT JOIN 
    RankedSuppliers sr ON sr.rank = 1
LEFT JOIN 
    HighValueOrders o ON o.o_orderkey IN (
        SELECT o_orderkey 
        FROM orders 
        WHERE o_custkey IN (
            SELECT c_custkey 
            FROM customer 
            WHERE c_acctbal > 5000
        )
    )
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
ORDER BY 
    p.p_partkey DESC, order_value DESC;
