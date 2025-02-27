WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        LENGTH(p.p_name) AS name_length,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
FilteredParts AS (
    SELECT 
        rp.p_partkey, 
        rp.p_name, 
        rp.p_brand
    FROM 
        RankedParts rp
    WHERE 
        rp.supplier_count > 5 AND 
        rp.name_length > 10
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey
    HAVING 
        total_order_value > 1000
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.p_brand,
    COUNT(DISTINCT co.o_orderkey) AS num_orders,
    AVG(co.total_order_value) AS avg_order_value
FROM 
    FilteredParts fp
LEFT JOIN 
    CustomerOrders co ON EXISTS (
        SELECT 1
        FROM lineitem l 
        WHERE l.l_partkey = fp.p_partkey 
        AND l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)
    )
GROUP BY 
    fp.p_partkey, fp.p_name, fp.p_brand
ORDER BY 
    num_orders DESC, avg_order_value DESC;
