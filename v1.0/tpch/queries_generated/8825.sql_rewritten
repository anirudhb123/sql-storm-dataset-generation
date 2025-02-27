WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-10-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
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
        s.total_supply_cost,
        s.part_count,
        RANK() OVER (ORDER BY s.total_supply_cost DESC) AS supplier_rank
    FROM 
        SupplierStats s
    WHERE 
        s.total_supply_cost > 10000
),
OrderDetails AS (
    SELECT 
        lo.l_orderkey,
        lo.l_partkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS revenue,
        COUNT(DISTINCT lo.l_linenumber) AS line_count
    FROM 
        lineitem lo
    JOIN 
        RankedOrders ro ON lo.l_orderkey = ro.o_orderkey
    GROUP BY 
        lo.l_orderkey, lo.l_partkey
)
SELECT 
    nt.n_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(od.revenue) AS total_revenue,
    AVG(ts.total_supply_cost) AS avg_supply_cost_per_supplier
FROM 
    nation nt
JOIN 
    customer c ON nt.n_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    OrderDetails od ON o.o_orderkey = od.l_orderkey
JOIN 
    TopSuppliers ts ON ts.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = od.l_partkey 
        ORDER BY ps.ps_supplycost DESC 
        LIMIT 1
    )
GROUP BY 
    nt.n_name
ORDER BY 
    total_revenue DESC;