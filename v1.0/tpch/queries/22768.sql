WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_cost,
        AVG(s.s_acctbal) AS avg_balance
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_value,
        COUNT(l.l_orderkey) AS lineitem_count,
        MAX(l.l_shipdate) AS last_shipdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F') 
        AND l.l_returnflag IS NULL
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT fo.o_orderkey) AS order_count,
        SUM(fo.net_value) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        FilteredOrders fo ON c.c_custkey = fo.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(fo.net_value) IS NOT NULL
        OR COUNT(DISTINCT fo.o_orderkey) > 0
)
SELECT 
    rp.p_name, 
    rp.p_retailprice,
    ss.total_parts,
    COALESCE(co.order_count, 0) AS total_customers,
    COALESCE(co.total_spent, 0) AS total_spent,
    (CASE WHEN ss.avg_balance IS NULL THEN 'Unknown' ELSE CAST(ss.avg_balance AS VARCHAR) END) AS avg_balance_status,
    (SELECT COUNT(*) FROM nation n WHERE n.n_regionkey IS NULL) AS region_not_assigned
FROM 
    RankedParts rp
JOIN 
    SupplierStats ss ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ss.s_suppkey)
LEFT JOIN 
    CustomerOrders co ON co.order_count > 0
WHERE 
    rp.rn = 1
ORDER BY 
    rp.p_retailprice DESC, 
    ss.total_cost ASC, 
    co.total_spent DESC;
