WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_name, 
        ROW_NUMBER() OVER (PARTITION BY c.c_name ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
), 
RegionalSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name, 
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, r.r_name
), 
TopSuppliers AS (
    SELECT 
        region_name, 
        nation_name, 
        s.s_name, 
        RANK() OVER (PARTITION BY region_name ORDER BY total_supply_cost DESC) AS supplier_rank
    FROM 
        RegionalSuppliers s
)
SELECT 
    ro.o_orderkey, 
    ro.o_orderdate, 
    ro.o_totalprice, 
    ro.c_name, 
    ts.s_name AS top_supplier_name 
FROM 
    RankedOrders ro
JOIN 
    lineitem li ON ro.o_orderkey = li.l_orderkey
JOIN 
    TopSuppliers ts ON li.l_suppkey = ts.s_suppkey 
WHERE 
    ts.supplier_rank = 1
ORDER BY 
    ro.o_orderdate DESC, ro.o_totalprice DESC;
