WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '2023-01-01' AND l.l_shipdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
TopRevenueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        r.revenue
    FROM 
        RankedOrders r
    WHERE 
        r.order_rank <= 10
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spending
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 100000
),
FinalAnalysis AS (
    SELECT 
        c.c_name,
        co.order_count,
        co.total_spending,
        si.s_name AS supplier_name,
        si.total_supply_cost,
        CASE 
            WHEN si.total_supply_cost IS NULL THEN 'No Supply Cost'
            ELSE 'Supply Cost Exists'
        END AS supply_cost_status
    FROM 
        CustomerOrders co
    LEFT JOIN 
        SupplierInfo si ON co.order_count > 5
    LEFT JOIN 
        region r ON si.total_supply_cost IS NOT NULL
    WHERE 
        r.r_name IS NULL OR r.r_name LIKE 'East%'
)
SELECT 
    fa.c_name,
    fa.order_count,
    fa.total_spending,
    fa.supplier_name,
    fa.total_supply_cost,
    fa.supply_cost_status
FROM 
    FinalAnalysis fa
ORDER BY 
    fa.total_spending DESC;
