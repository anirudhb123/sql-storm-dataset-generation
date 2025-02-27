WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn,
        CASE 
            WHEN o.o_totalprice > 1000 THEN 'High Value' 
            WHEN o.o_totalprice BETWEEN 500 AND 1000 THEN 'Medium Value' 
            ELSE 'Low Value' 
        END AS order_value_category
    FROM 
        orders o
),
TopOrders AS (
    SELECT 
        ro.o_orderkey, 
        ro.o_orderdate, 
        ro.o_totalprice,
        ro.order_value_category,
        COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name
    FROM 
        RankedOrders ro
    LEFT JOIN 
        lineitem l ON ro.o_orderkey = l.l_orderkey
    LEFT JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ro.rn <= 5
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(to.o_orderkey) AS total_orders,
        SUM(to.o_totalprice) AS total_spent,
        ARRAY_AGG(to.order_value_category) AS value_categories
    FROM
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        TopOrders to ON o.o_orderkey = to.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FinalReport AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_orders,
        co.total_spent,
        CASE 
            WHEN co.total_spent IS NULL THEN 'No Purchases'
            WHEN co.total_spent > 2000 THEN 'Premium Customer'
            ELSE 'Regular Customer'
        END AS customer_tier,
        STRING_AGG(to.order_value_category, ', ') AS categorical_orders
    FROM 
        CustomerOrders co
    LEFT JOIN 
        TopOrders to ON co.total_orders > 0
    GROUP BY 
        co.c_custkey, co.c_name, co.total_orders, co.total_spent
)
SELECT 
    DISTINCT fr.cust_name,
    fr.customer_tier,
    fr.categorical_orders
FROM 
    FinalReport fr
WHERE 
    fr.customer_tier != 'No Purchases'
ORDER BY 
    fr.total_spent DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
