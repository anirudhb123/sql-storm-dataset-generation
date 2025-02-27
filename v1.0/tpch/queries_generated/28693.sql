WITH CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
OrderLineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice) AS total_price,
        SUM(l.l_discount) AS total_discounted_price,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    cus.c_name,
    cus.total_orders,
    cus.total_spent,
    cus.last_order_date,
    psd.total_available,
    psd.avg_supply_cost,
    ols.total_quantity,
    ols.total_price,
    ols.total_discounted_price,
    ols.unique_parts
FROM 
    CustomerOrderSummary cus
JOIN 
    OrderLineItemSummary ols ON ols.l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = cus.c_custkey)
LEFT JOIN 
    PartSupplierDetails psd ON psd.ps_partkey IN (SELECT l_partkey FROM lineitem WHERE l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = cus.c_custkey))
WHERE 
    cus.total_spent > 5000
ORDER BY 
    cus.total_spent DESC, cus.last_order_date DESC;
