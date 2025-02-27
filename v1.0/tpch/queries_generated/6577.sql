WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal
    FROM 
        RankedSuppliers s
    WHERE 
        supplier_rank <= 10
),
RecentOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_totalprice, 
        o.o_orderdate
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -6, CURRENT_DATE)
)
SELECT 
    rs.s_name, 
    rs.s_acctbal, 
    COUNT(ro.o_orderkey) AS order_count, 
    SUM(ro.o_totalprice) AS total_order_value
FROM 
    TopSuppliers rs
LEFT JOIN 
    lineitem li ON li.l_suppkey = rs.s_suppkey
LEFT JOIN 
    RecentOrders ro ON li.l_orderkey = ro.o_orderkey
GROUP BY 
    rs.s_suppkey, rs.s_name, rs.s_acctbal
ORDER BY 
    total_order_value DESC;
