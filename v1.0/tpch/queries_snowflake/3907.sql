
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
        AND l.l_shipdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_regionkey,
        r.r_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
RankedSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_avail_qty,
        ss.total_supply_cost,
        RANK() OVER (ORDER BY ss.total_avail_qty DESC) AS rank_based_on_availability
    FROM 
        SupplierStats ss
)
SELECT 
    os.o_orderkey,
    os.total_revenue,
    rs.s_name,
    rs.total_avail_qty,
    rs.total_supply_cost,
    CASE 
        WHEN rs.total_supply_cost IS NULL THEN 'Not Applicable'
        ELSE CONCAT('Total Supply Cost: $', CAST(ROUND(rs.total_supply_cost, 2) AS VARCHAR))
    END AS supply_cost_info,
    COUNT(l.l_orderkey) FILTER (WHERE l.l_linestatus = 'O') AS open_line_items,
    COALESCE(n.n_name, 'Unknown Nation') AS supplier_nation
FROM 
    OrderSummary os
LEFT JOIN 
    RankedSuppliers rs ON os.o_orderkey = rs.s_suppkey
LEFT JOIN 
    customer c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = os.o_orderkey)
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    lineitem l ON l.l_orderkey = os.o_orderkey
WHERE 
    os.total_revenue > 1000 AND 
    (rs.total_avail_qty IS NULL OR rs.total_avail_qty >= 500)
GROUP BY 
    os.o_orderkey,
    os.total_revenue,
    rs.s_name,
    rs.total_avail_qty,
    rs.total_supply_cost,
    rs.rank_based_on_availability,
    n.n_name
ORDER BY 
    os.total_revenue DESC,
    rs.rank_based_on_availability ASC;
