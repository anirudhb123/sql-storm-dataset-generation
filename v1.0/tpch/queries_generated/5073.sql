WITH SupplierCostRanking AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS cost_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        SupplierCostRanking scr ON l.l_suppkey = scr.s_suppkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' 
        AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.revenue,
    scr.total_cost,
    scr.cost_rank
FROM 
    TopSuppliers ts
JOIN 
    SupplierCostRanking scr ON ts.s_suppkey = scr.s_suppkey
WHERE 
    ts.revenue > 1000000
ORDER BY 
    scr.cost_rank, ts.revenue DESC
LIMIT 10;
