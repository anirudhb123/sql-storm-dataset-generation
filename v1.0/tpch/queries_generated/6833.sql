WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.n_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.n_nationkey
),
HighCostSuppliers AS (
    SELECT 
        sc.s_suppkey, 
        sc.s_name, 
        na.n_name AS nation_name, 
        sc.total_supply_cost
    FROM 
        SupplierCosts sc
    JOIN 
        nation na ON sc.n_nationkey = na.n_nationkey
    WHERE 
        sc.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierCosts)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate, 
        sc.total_supply_cost
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        HighCostSuppliers sc ON o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = sc.s_suppkey)
)
SELECT 
    co.c_custkey, 
    co.c_name, 
    COUNT(co.o_orderkey) AS order_count, 
    SUM(co.o_totalprice) AS total_spent,
    AVG(co.total_supply_cost) AS avg_supplier_cost
FROM 
    CustomerOrders co
GROUP BY 
    co.c_custkey, co.c_name
ORDER BY 
    total_spent DESC
LIMIT 10;
