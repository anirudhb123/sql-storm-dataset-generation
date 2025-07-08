WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_size ORDER BY p.p_retailprice DESC) AS rn,
        CONCAT('Name: ', p.p_name, ', Price: ', CAST(p.p_retailprice AS VARCHAR(12))) AS part_info
    FROM 
        part p
    WHERE 
        p.p_retailprice BETWEEN 100 AND 1000
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
NationSupplierInfo AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
    HAVING 
        COUNT(s.s_suppkey) > 0
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COALESCE(COUNT(o.o_orderkey), 0) AS order_count,
        COALESCE(SUM(o.o_totalprice), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    rp.part_info,
    nsi.nation_name,
    nsi.supplier_count,
    co.order_count,
    co.total_spent,
    CASE 
        WHEN co.total_spent IS NULL THEN 'No Orders'
        WHEN co.total_spent > 5000 THEN 'High Roller'
        ELSE 'Casual'
    END AS customer_type,
    CASE 
        WHEN nsi.supplier_count IS NULL OR nsi.supplier_count = 0 THEN 'No Suppliers'
        ELSE 'Has Suppliers'
    END AS supplier_status
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    nation n ON ps.ps_suppkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = ps.ps_suppkey)
JOIN 
    NationSupplierInfo nsi ON n.n_name = nsi.nation_name
LEFT JOIN 
    CustomerOrders co ON nsi.supplier_count = co.order_count  
WHERE 
    rp.rn = 1 
    AND nsi.avg_acctbal IS NOT NULL
ORDER BY 
    rp.p_retailprice DESC
LIMIT 100;
