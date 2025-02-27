WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey
),
TopRegions AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS region_rank
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_regionkey, r.r_name
)
SELECT 
    rss.supp_name,
    rss.total_available,
    rss.avg_supply_cost,
    co.order_count,
    co.total_spent,
    tr.r_name AS top_region_name,
    tr.region_rank
FROM 
    SupplierStats rss
LEFT JOIN 
    CustomerOrders co ON co.order_count > 0
JOIN 
    TopRegions tr ON rss.total_parts > 5
WHERE 
    rss.avg_supply_cost > (SELECT AVG(avg_supply_cost) FROM SupplierStats)
ORDER BY 
    rss.total_available DESC, co.total_spent DESC;
