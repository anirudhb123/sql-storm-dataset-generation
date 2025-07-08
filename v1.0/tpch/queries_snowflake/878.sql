
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_orderpriority,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
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
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.total_orders,
        c.total_spent,
        RANK() OVER (ORDER BY c.total_spent DESC) AS customer_rank
    FROM 
        CustomerOrders c
    WHERE 
        c.total_orders > 5
)
SELECT 
    cust.c_name,
    cust.total_spent,
    COUNT(DISTINCT li.l_orderkey) AS total_distinct_orders,
    SUM(CASE WHEN li.l_discount > 0 THEN li.l_extendedprice * (1 - li.l_discount) ELSE 0 END) AS total_discounted_price,
    COALESCE(SUM(sp.total_supply_cost), 0) AS total_supply_cost
FROM 
    TopCustomers cust
LEFT JOIN 
    orders o ON cust.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem li ON o.o_orderkey = li.l_orderkey
LEFT JOIN 
    SupplierParts sp ON sp.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
WHERE 
    cust.customer_rank <= 10
GROUP BY 
    cust.c_name, cust.total_spent
HAVING 
    SUM(li.l_quantity) IS NOT NULL AND SUM(li.l_quantity) > 0
ORDER BY 
    cust.total_spent DESC;
