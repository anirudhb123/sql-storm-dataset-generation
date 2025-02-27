WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL AND
        p.p_size BETWEEN 1 AND 20
), 

CustomerOrders AS (
    SELECT
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey
), 

SupplierStats AS (
    SELECT DISTINCT
        s.s_suppkey,
        CASE 
            WHEN SUM(ps.ps_availqty) IS NULL THEN 0
            ELSE SUM(ps.ps_availqty)
        END AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)

SELECT 
    cp.c_custkey,
    cp.total_spent,
    rp.p_partkey,
    rp.p_name,
    rp.p_retailprice,
    ss.total_available,
    ss.avg_supply_cost
FROM 
    CustomerOrders cp
CROSS JOIN 
    RankedParts rp
FULL OUTER JOIN 
    SupplierStats ss ON rp.p_partkey = ss.total_available
WHERE 
    (cp.total_spent > 1000 OR ss.avg_supply_cost < 25.00) AND
    NOT (rp.p_name LIKE '%cheap%' AND ss.total_available < 10)
ORDER BY 
    cp.total_spent ASC NULLS FIRST, rp.p_retailprice DESC
LIMIT 10
OFFSET 5;
