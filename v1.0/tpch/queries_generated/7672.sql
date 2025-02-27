WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
),
SumLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
TopSuppliers AS (
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
    ORDER BY 
        total_supply_cost DESC 
    LIMIT 10
)
SELECT 
    ro.o_orderkey,
    ro.o_orderstatus,
    ro.o_totalprice,
    ro.o_orderdate,
    sli.total_revenue,
    ts.s_name,
    ts.total_supply_cost
FROM 
    RankedOrders ro
LEFT JOIN 
    SumLineItems sli ON ro.o_orderkey = sli.l_orderkey
JOIN 
    TopSuppliers ts ON ts.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT l.l_partkey 
            FROM lineitem l 
            WHERE l.l_orderkey = ro.o_orderkey
        )
        ORDER BY ps.ps_supplycost DESC 
        LIMIT 1
    )
WHERE 
    ro.order_rank <= 5
ORDER BY 
    ro.o_orderdate;
