WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_container, 
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_availability,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_container
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS recent_order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
FinalResults AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_container,
        rp.supplier_count,
        rp.total_availability,
        co.c_custkey,
        co.c_name,
        co.o_orderkey,
        co.o_orderdate,
        co.o_totalprice
    FROM 
        RankedParts rp
    LEFT JOIN 
        CustomerOrders co ON rp.supplier_count > 5 AND rp.rank = 1
)
SELECT 
    f.p_partkey,
    f.p_name,
    f.p_brand,
    f.p_container,
    f.supplier_count,
    f.total_availability,
    f.c_custkey,
    f.c_name,
    f.o_orderkey,
    f.o_orderdate,
    f.o_totalprice,
    CONCAT('Part: ', f.p_name, ' | Customer: ', f.c_name) AS description
FROM 
    FinalResults f
WHERE 
    f.o_orderdate >= DATEADD(month, -12, CURRENT_DATE)
ORDER BY 
    f.total_availability DESC, f.o_totalprice DESC;
