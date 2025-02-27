WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),

CustomerTotalOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),

HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
),

NationSupplierCount AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)

SELECT 
    ns.n_name,
    ns.supplier_count,
    cs.c_name,
    cs.total_orders,
    cs.total_spent,
    ss.total_available_quantity,
    ss.total_supply_value
FROM 
    NationSupplierCount ns
FULL OUTER JOIN 
    CustomerTotalOrders cs ON ns.n_name = 
        (SELECT n.n_name 
         FROM nation n 
         WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = cs.c_custkey))
LEFT JOIN 
    SupplierSummary ss ON ss.total_supply_value > 0
WHERE 
    ns.supplier_count >= 5
ORDER BY 
    ss.total_supply_value DESC NULLS LAST;
