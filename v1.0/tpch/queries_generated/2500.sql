WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.total_revenue
    FROM 
        RankedOrders ro
    WHERE 
        ro.revenue_rank <= 10
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
)
SELECT 
    coalesce(o.o_orderkey, 'No Orders') AS order_key,
    coalesce(o.o_orderdate, 'N/A') AS order_date,
    COALESCE(td.s_name, 'Unknown Supplier') AS supplier_name,
    COALESCE(td.total_supply_cost, 0) AS total_supply_cost,
    CASE 
        WHEN o.total_revenue IS NULL THEN 'No Revenue'
        ELSE CAST(o.total_revenue AS DECIMAL(12, 2))
    END AS revenue
FROM 
    TopOrders o
LEFT OUTER JOIN 
    SupplierDetails td ON o.o_orderkey = td.s_nationkey
ORDER BY 
    o.total_revenue DESC NULLS LAST;
