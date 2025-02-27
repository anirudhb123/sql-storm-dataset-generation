WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank_price
    FROM 
        part p
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT p.p_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        MAX(s.s_acctbal) AS max_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS line_count,
        DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS rank_recent
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(ro.total_order_value) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        RecentOrders ro ON c.c_custkey = ro.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    cs.c_custkey,
    cs.order_count,
    COALESCE(cs.total_spent, 0) AS total_spent,
    ss.part_count,
    ss.total_supply_cost,
    rp.p_name,
    CASE 
        WHEN cs.order_count > 5 THEN 'High'
        WHEN cs.order_count BETWEEN 1 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS order_segment
FROM 
    CustomerOrderDetails cs
LEFT JOIN 
    SupplierStats ss ON cs.c_custkey = ss.part_count
JOIN 
    RankedParts rp ON rp.rank_price = 1
WHERE 
    ss.max_acctbal IS NOT NULL
    AND (cs.order_count IS NULL OR cs.total_spent IS NOT NULL)
ORDER BY 
    total_spent DESC, cs.c_custkey ASC
LIMIT 100;
