WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_size,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_size ORDER BY p.p_retailprice DESC) AS size_rank
    FROM 
        part p
    WHERE 
        p.p_size IS NOT NULL
),
SupplierStats AS (
    SELECT 
        s.s_nationkey,
        COUNT(*) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_price
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
FilteredLineitems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_net_price
    FROM 
        lineitem l
    WHERE 
        l.l_quantity > 0
    GROUP BY 
        l.l_orderkey, l.l_partkey
)

SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_retailprice,
    COALESCE(ss.total_acctbal, 0) AS supplier_total_acctbal,
    co.total_orders,
    co.total_spent,
    COALESCE(co.total_spent / NULLIF(co.total_orders, 0), 0) AS avg_order_value,
    CASE 
        WHEN rp.size_rank = 1 THEN 'Most Expensive'
        ELSE 'Other'
    END AS Price_Category
FROM 
    RankedParts rp
LEFT OUTER JOIN 
    SupplierStats ss ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost = (SELECT MAX(ps2.ps_supplycost) FROM partsupp ps2 WHERE ps2.ps_partkey = rp.p_partkey))
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = (SELECT TOP 1 c.c_custkey FROM customer c ORDER BY c.c_acctbal DESC)
WHERE 
    rp.p_size > 10
ORDER BY 
    rp.p_retailprice DESC, avg_order_value DESC;
