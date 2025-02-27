WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.n_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS net_revenue
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
    HAVING 
        SUM(li.l_extendedprice * (1 - li.l_discount)) > 10000
),
SupplierOrderStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT lo.o_orderkey) AS total_orders,
        SUM(lo.net_revenue) AS total_revenue
    FROM 
        RankedSuppliers s
    LEFT JOIN 
        lineitem l ON s.s_suppkey = l.l_suppkey
    LEFT JOIN 
        HighValueOrders lo ON l.l_orderkey = lo.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    reg.r_name,
    ns.n_name,
    COALESCE(sos.total_orders, 0) AS total_orders,
    COALESCE(sos.total_revenue, 0) AS total_revenue,
    CASE 
        WHEN COALESCE(sos.total_revenue, 0) > 50000 THEN 'High Revenue'
        ELSE 'Lower Revenue'
    END AS revenue_category
FROM 
    nation ns
JOIN 
    region reg ON ns.n_regionkey = reg.r_regionkey
LEFT JOIN 
    SupplierOrderStats sos ON ns.n_nationkey = sos.s_suppkey
WHERE 
    reg.r_name LIKE 'A%'
ORDER BY 
    total_revenue DESC, total_orders ASC;
