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
TopSuppliers AS (
    SELECT 
        nation_name, 
        s.s_suppkey, 
        s.s_name, 
        total_supply_cost 
    FROM 
        RankedSuppliers rs 
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey 
    WHERE 
        rs.rank <= 3
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        C.c_name AS customer_name,
        EXTRACT(YEAR FROM o.o_orderdate) AS order_year
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
OrderDetails AS (
    SELECT 
        lo.l_orderkey,
        lo.l_partkey,
        lo.l_quantity,
        lo.l_extendedprice,
        so.total_supply_cost,
        ro.customer_name,
        ro.order_year
    FROM 
        lineitem lo
    JOIN 
        RecentOrders ro ON lo.l_orderkey = ro.o_orderkey
    JOIN 
        TopSuppliers so ON so.nation_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE lo.l_suppkey = s.s_suppkey))
)
SELECT 
    od.customer_name,
    od.order_year,
    SUM(od.l_extendedprice) AS total_extended_price,
    SUM(od.l_quantity) AS total_quantity,
    SUM(od.total_supply_cost) as total_supply_cost
FROM 
    OrderDetails od
GROUP BY 
    od.customer_name, od.order_year
ORDER BY 
    od.order_year, SUM(od.l_extendedprice) DESC;
