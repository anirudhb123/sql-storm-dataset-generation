WITH PartSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
SupplierRegion AS (
    SELECT 
        s.s_suppkey,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    ps.p_partkey,
    ps.p_name,
    co.total_orders,
    co.total_spent,
    sr.nation_name,
    sr.region_name,
    COALESCE(sr.s_acctbal, 0) AS supplier_account_balance
FROM 
    PartSummary ps
LEFT JOIN 
    CustomerOrders co ON co.total_orders > 0
LEFT JOIN 
    SupplierRegion sr ON sr.rank = 1 
WHERE 
    ps.total_avail_qty IS NOT NULL 
    AND ps.avg_supply_cost < (SELECT AVG(avg_supply_cost) FROM PartSummary) 
ORDER BY 
    ps.total_avail_qty DESC, co.total_spent DESC
LIMIT 100;
