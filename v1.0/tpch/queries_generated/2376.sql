WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
), 
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT s.s_nationkey) AS number_of_nations
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey
), 
LineItemsSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linenumber) AS line_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        l.l_orderkey
) 
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.o_orderstatus,
    COALESCE(l.total_revenue, 0) AS order_revenue,
    l.line_count,
    s.total_supply_cost,
    s.number_of_nations,
    CASE 
        WHEN r.o_orderstatus = 'F' THEN 'Completed'
        WHEN r.o_orderstatus = 'P' THEN 'Pending'
        ELSE 'Unknown'
    END AS order_status_desc
FROM 
    RankedOrders r
LEFT JOIN 
    LineItemsSummary l ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierCosts s ON s.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_container LIKE '%BOX%')
WHERE 
    r.order_rank <= 10
ORDER BY 
    r.o_orderdate DESC, r.o_orderstatus;
