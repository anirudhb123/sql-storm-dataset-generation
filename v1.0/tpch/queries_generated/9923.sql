WITH OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice
), SupplierParts AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
), CustomerOrders AS (
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
)
SELECT 
    nac.n_name AS nation_name,
    SUM(od.total_revenue) AS total_revenue,
    SUM(sp.total_supply_cost) AS total_supply_cost,
    COUNT(DISTINCT co.c_custkey) AS unique_customers,
    SUM(co.total_spent) AS total_customer_spent,
    COUNT(DISTINCT od.o_orderkey) AS total_orders_processed
FROM 
    OrderDetails od
JOIN 
    nation nac ON nac.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey IN (SELECT DISTINCT o.o_custkey FROM orders o WHERE o.o_orderkey = od.o_orderkey))
JOIN 
    SupplierParts sp ON sp.ps_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = od.o_orderkey))
JOIN 
    CustomerOrders co ON co.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = od.o_orderkey)
GROUP BY 
    nac.n_name
ORDER BY 
    total_revenue DESC, total_customer_spent DESC;
