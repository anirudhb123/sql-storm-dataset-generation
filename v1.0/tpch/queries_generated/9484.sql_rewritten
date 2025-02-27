WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderstatus, 
        c.c_name, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
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
    LIMIT 5
)
SELECT 
    r.r_name AS region, 
    n.n_name AS nation, 
    COUNT(DISTINCT ro.o_orderkey) AS total_orders, 
    SUM(ro.o_totalprice) AS total_revenue, 
    ts.s_name AS top_supplier_name, 
    ts.total_supply_cost
FROM 
    RankedOrders ro
JOIN 
    nation n ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey))
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    TopSuppliers ts ON ts.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps JOIN lineitem li ON ps.ps_partkey = li.l_partkey WHERE li.l_orderkey = ro.o_orderkey)
GROUP BY 
    r.r_name, n.n_name, ts.s_name, ts.total_supply_cost
ORDER BY 
    total_revenue DESC, total_orders DESC
LIMIT 10;