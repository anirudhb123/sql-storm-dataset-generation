WITH RECURSIVE Customer_Order_Summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
Supplier_Part_Summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
Date_Comparison AS (
    SELECT 
        l.l_orderkey,
        DATEDIFF(l.l_shipdate, l.l_orderkey) AS shipping_days
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate IS NOT NULL
),
Filtered_Customers AS (
    SELECT 
        cust.c_custkey,
        cust.c_name,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_spend,
        COUNT(DISTINCT ord.o_orderkey) AS orders_count
    FROM 
        customer cust
    LEFT JOIN 
        orders ord ON cust.c_custkey = ord.o_custkey
    LEFT JOIN 
        lineitem l ON ord.o_orderkey = l.l_orderkey
    GROUP BY 
        cust.c_custkey, cust.c_name
    HAVING 
        total_spend > 10000 AND orders_count > 5
)
SELECT 
    cust.c_name AS customer_name,
    COALESCE(supp.s_name, 'No Supplier') AS supplier_name,
    summ.total_spent,
    part_summ.total_supply_value,
    SUM(CASE 
            WHEN d.shipping_days < 3 THEN 1 
            ELSE 0 
        END) AS expedited_shipments,
    MAX(summ.total_orders) OVER () AS max_orders
FROM 
    Filtered_Customers cust
LEFT JOIN 
    Customer_Order_Summary summ ON cust.c_custkey = summ.c_custkey
LEFT JOIN 
    Supplier_Part_Summary part_summ ON summ.c_custkey = part_summ.s_suppkey
LEFT JOIN 
    Date_Comparison d ON summ.c_custkey = d.l_orderkey
LEFT JOIN 
    supplier supp ON supp.s_nationkey = cust.c_nationkey
WHERE 
    summ.order_rank <= 10
GROUP BY 
    cust.c_name, supp.s_name, summ.total_spent, part_summ.total_supply_value
HAVING 
    part_summ.total_supply_value > 5000
ORDER BY 
    total_spent DESC;
