WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
RankedParts AS (
    SELECT 
        ps.p_partkey,
        ps.total_revenue,
        RANK() OVER (ORDER BY ps.total_revenue DESC) AS revenue_rank
    FROM 
        PartSummary ps
)
SELECT 
    r.r_name,
    n.n_name,
    s.s_name,
    stats.total_available_quantity,
    stats.avg_supply_cost,
    cust.c_name,
    cust.total_orders,
    cust.total_spent,
    rp.p_name,
    rp.total_revenue,
    rp.revenue_rank
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    SupplierStats stats ON s.s_suppkey = stats.s_suppkey
JOIN 
    CustomerOrders cust ON n.n_nationkey = cust.c_nationkey
JOIN 
    RankedParts rp ON stats.total_available_quantity > 1000 AND cust.total_orders > 10
WHERE 
    rp.revenue_rank <= 10
ORDER BY 
    rp.total_revenue DESC, cust.total_spent DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
