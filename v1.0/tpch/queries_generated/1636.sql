WITH SupplierAggregates AS (
    SELECT 
        s_suppkey,
        s_name,
        SUM(ps_availqty) AS total_available,
        AVG(ps_supplycost) AS avg_supply_cost
    FROM 
        supplier
    JOIN 
        partsupp ON supplier.s_suppkey = partsupp.ps_suppkey
    GROUP BY 
        s_suppkey, s_name
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
    WHERE 
        o.o_orderstatus IN ('O', 'F') -- Open or Filled
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
        COUNT(DISTINCT l.l_partkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey
),
RankedOrders AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY order_value DESC) AS order_rank
    FROM 
        OrderDetails o
)
SELECT 
    s.s_name AS supplier_name,
    ca.c_name AS customer_name,
    co.total_orders,
    co.total_spent,
    SUM(ro.order_value) AS total_order_value,
    COUNT(ro.o_orderkey) AS total_orders_detailed,
    MAX(co.total_orders) OVER () AS max_orders_by_customer,
    MIN(co.total_spent) OVER () AS min_spent_by_customer
FROM 
    SupplierAggregates s
INNER JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = (SELECT 
                                              c.c_custkey 
                                          FROM 
                                              customer c 
                                          WHERE 
                                              c.c_nationkey = (SELECT 
                                                                n.n_nationkey 
                                                              FROM 
                                                                nation n 
                                                              WHERE 
                                                                n.n_name = 'FRANCE')
                                          LIMIT 1)
JOIN 
    RankedOrders ro ON ps.ps_partkey = ro.o_orderkey
WHERE 
    s.total_available > 100 AND
    s.avg_supply_cost < 50
GROUP BY 
    s.s_name, ca.c_name, co.total_orders, co.total_spent
HAVING 
    COUNT(ro.o_orderkey) > 5
ORDER BY 
    total_order_value DESC NULLS LAST;
