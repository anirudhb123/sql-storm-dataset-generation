WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS rank_order
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice) AS total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        lineitem l ON ro.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ro.rank_order <= 5
    GROUP BY 
        ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, ro.c_name, p.p_name
),
FinalResults AS (
    SELECT 
        c.n_nationkey,
        COUNT(DISTINCT to.o_orderkey) AS order_count,
        SUM(to.total_quantity) AS total_items_sold,
        AVG(to.total_revenue) AS avg_revenue_per_order
    FROM 
        TopOrders to
    JOIN 
        customer c ON to.c_name = c.c_name
    GROUP BY 
        c.n_nationkey
)
SELECT 
    r.r_name AS region_name,
    fr.order_count,
    fr.total_items_sold,
    fr.avg_revenue_per_order
FROM 
    FinalResults fr
JOIN 
    nation n ON fr.n_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
ORDER BY 
    r.r_name, fr.order_count DESC;
