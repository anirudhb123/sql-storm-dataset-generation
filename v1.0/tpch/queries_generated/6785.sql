WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), HighRevenueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.total_revenue
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 10
), SupplierInfo AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_suppkey
)
SELECT 
    hro.o_orderkey, 
    hro.o_orderdate, 
    hro.total_revenue, 
    si.total_supply_cost,
    CASE 
        WHEN hro.total_revenue > 10000 THEN 'High Revenue'
        ELSE 'Moderate Revenue'
    END AS revenue_category
FROM 
    HighRevenueOrders hro
JOIN 
    SupplierInfo si ON si.ps_suppkey IN (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        JOIN 
            lineitem l ON ps.ps_partkey = l.l_partkey 
        WHERE 
            l.l_orderkey = hro.o_orderkey
    )
ORDER BY 
    hro.total_revenue DESC;
