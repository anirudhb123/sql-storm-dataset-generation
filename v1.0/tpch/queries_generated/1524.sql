WITH SupplierPartCost AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), 
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 100
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sp.total_supply_cost
    FROM 
        SupplierPartCost sp
    JOIN 
        supplier s ON sp.s_suppkey = s.s_suppkey
    WHERE 
        sp.total_supply_cost > 10000
    ORDER BY 
        sp.total_supply_cost DESC
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
)
SELECT 
    cu.c_name,
    COALESCE(SUM(lo.l_extendedprice * (1 - lo.l_discount)), 0) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS number_of_orders,
    hs.s_name AS high_value_supplier
FROM 
    CustomerOrderSummary cu
LEFT JOIN 
    RecentOrders ro ON cu.c_custkey = ro.o_orderkey
LEFT JOIN 
    lineitem lo ON lo.l_orderkey = ro.o_orderkey
LEFT JOIN 
    HighValueSuppliers hs ON hs.s_suppkey IN (
        SELECT DISTINCT ps.ps_suppkey
        FROM partsupp ps
        JOIN lineitem li ON ps.ps_partkey = li.l_partkey
        WHERE li.l_orderkey = ro.o_orderkey
    )
WHERE 
    cu.total_orders > 5
GROUP BY 
    cu.c_name, hs.s_name
HAVING 
    total_revenue > 5000
ORDER BY 
    total_revenue DESC, cu.c_name;
