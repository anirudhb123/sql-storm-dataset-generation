WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
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
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        MAX(l.l_shipdate) AS last_shipdate
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)

SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT cs.c_custkey) AS total_customers,
    SUM(cs.total_spent) AS total_customer_spent,
    AVG(cs.total_orders) AS avg_orders_per_customer,
    SUM(ss.total_supply_cost) AS total_supplier_cost,
    MAX(ld.last_shipdate) AS latest_ship_date
FROM 
    nation n
LEFT JOIN 
    customer cs ON n.n_nationkey = cs.c_nationkey
LEFT JOIN 
    CustomerOrders co ON cs.c_custkey = co.c_custkey
LEFT JOIN 
    SupplierStats ss ON (ss.part_count > 0)
LEFT JOIN 
    LineItemDetails ld ON (ld.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey))
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT cs.c_custkey) > 0
ORDER BY 
    total_customer_spent DESC
LIMIT 10;
