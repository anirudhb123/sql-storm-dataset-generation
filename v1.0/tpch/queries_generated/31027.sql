WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'P')
),
TotalSales AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        p.p_partkey
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
RankedRevenue AS (
    SELECT 
        p.p_name,
        p.p_brand,
        p.p_type,
        ts.total_revenue,
        sr.total_supply_cost,
        RANK() OVER (ORDER BY ts.total_revenue DESC) AS revenue_rank
    FROM 
        part p
    JOIN 
        TotalSales ts ON p.p_partkey = ts.p_partkey
    LEFT JOIN 
        SupplierSales sr ON sr.total_supply_cost IS NOT NULL
)
SELECT 
    r.r_name,
    COUNT(DISTINCT co.o_orderkey) AS order_count,
    AVG(COALESCE(co.o_totalprice, 0)) AS average_order_value,
    SUM(CASE WHEN rr.revenue_rank <= 10 THEN rr.total_revenue ELSE 0 END) AS top_revenue_from_parts,
    MAX(rr.total_supply_cost) AS highest_supply_cost
FROM 
    region r
LEFT JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    CustomerOrders co ON co.o_orderkey = l.l_orderkey
LEFT JOIN 
    RankedRevenue rr ON rr.p_type IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT co.o_orderkey) > 10
ORDER BY 
    average_order_value DESC, 
    highest_supply_cost ASC;
