WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
HighValueSuppliers AS (
    SELECT 
        nation_name,
        s_name,
        total_supply_cost
    FROM 
        RankedSuppliers
    WHERE 
        rank <= 5
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS total_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    o.order_date,
    o.total_sales,
    o.total_items,
    hv.nation_name,
    hv.s_name,
    hv.total_supply_cost
FROM 
    OrderSummary o
JOIN 
    HighValueSuppliers hv ON o.total_sales >= 10000
ORDER BY 
    o.order_date, hv.total_supply_cost DESC;
