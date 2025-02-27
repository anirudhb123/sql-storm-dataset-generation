WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_comment LIKE '%special%'
), SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_comment,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_comment LIKE '%premium%'
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_address LIKE '%New York%'
    GROUP BY 
        c.c_custkey, c.c_name, c.c_mktsegment
), LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    si.nation_name,
    co.order_count,
    co.total_spent,
    lis.revenue,
    lis.distinct_parts
FROM 
    RankedParts rp
JOIN 
    SupplierInfo si ON EXISTS (
        SELECT 1 
        FROM partsupp ps 
        WHERE ps.ps_partkey = rp.p_partkey AND ps.ps_suppkey = si.s_suppkey
    )
JOIN 
    CustomerOrders co ON EXISTS (
        SELECT 1 
        FROM orders o 
        WHERE o.o_custkey = co.c_custkey AND o.o_orderkey IN (
            SELECT l.l_orderkey 
            FROM lineitem l 
            WHERE l.l_orderkey = o.o_orderkey
        )
    )
JOIN 
    LineItemSummary lis ON lis.l_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_custkey = co.c_custkey
    )
WHERE 
    rp.rn = 1 AND co.order_count > 5
ORDER BY 
    rp.p_retailprice DESC, si.nation_name ASC;
