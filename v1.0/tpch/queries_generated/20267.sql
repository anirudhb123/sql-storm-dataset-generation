WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 20
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.total_value > 100000
)
SELECT 
    rp.p_name,
    CASE 
        WHEN cs.order_count IS NULL THEN 'No Orders'
        ELSE 'Orders Placed'
    END AS order_status,
    ss.part_count,
    ss.total_value,
    cs.total_spent,
    COUNT(DISTINCT hvs.s_suppkey) OVER (PARTITION BY rp.p_partkey) AS supplier_count,
    CONCAT(rp.p_name, ' - ', COALESCE(n.n_name, 'Unknown Nation')) AS part_and_nation
FROM 
    RankedParts rp
LEFT JOIN 
    CustomerOrders cs ON rp.p_partkey = cs.c_custkey
LEFT JOIN 
    SupplierStats ss ON rp.p_partkey = ss.part_count
LEFT JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = cs.c_custkey LIMIT 1)
LEFT JOIN 
    HighValueSuppliers hvs ON hvs.s_suppkey = rp.p_partkey
WHERE 
    (rp.rn <= 5 OR rp.p_retailprice IS NULL)
    AND (ss.total_value IS NOT NULL OR ss.part_count IS NOT NULL)
ORDER BY 
    rp.p_name ASC, 
    ss.total_value DESC NULLS LAST;
