WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        AVG(o.o_totalprice) AS avg_order_value,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        COUNT(o.o_orderkey) > 5
),
TopProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity_sold
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    ORDER BY 
        total_quantity_sold DESC
    LIMIT 10
)
SELECT 
    r.r_name,
    ns.n_name,
    COALESCE(SUM(sc.total_supply_cost), 0) AS total_supply_cost,
    COUNT(DISTINCT cs.c_custkey) AS number_of_customers,
    AVG(cs.avg_order_value) AS average_customer_order_value,
    STRING_AGG(DISTINCT tp.p_name, ', ') AS top_products
FROM 
    region r
LEFT JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN 
    supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierCosts sc ON s.s_suppkey = sc.ps_partkey
LEFT JOIN 
    CustomerStats cs ON cs.c_custkey = s.s_suppkey
LEFT JOIN 
    TopProducts tp ON tp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name, ns.n_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 2
ORDER BY 
    total_supply_cost DESC;
