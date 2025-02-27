WITH SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), 
CustomerOrders AS (
    SELECT 
        o.o_custkey,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('F', 'P')
    GROUP BY 
        o.o_custkey
), 
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.total_order_value,
        DENSE_RANK() OVER (ORDER BY co.total_order_value DESC) AS rank
    FROM 
        customer c
    JOIN 
        CustomerOrders co ON c.c_custkey = co.o_custkey
), 
PartSupplierAndCustomer AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        sc.total_cost,
        tc.c_name,
        tc.total_order_value
    FROM 
        part p
    LEFT JOIN 
        SupplierCost sc ON p.p_partkey = sc.ps_partkey
    LEFT JOIN 
        TopCustomers tc ON tc.rank <= 10
), 
AggregatedResults AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(SUM(r.total_order_value), 0) AS total_customer_orders,
        AVG(p.p_retailprice) AS avg_retail_price,
        COUNT(DISTINCT tc.c_custkey) AS distinct_customers
    FROM 
        partsupplierandcustomer p
    LEFT JOIN 
        TopCustomers tc ON p.c_name = tc.c_name
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.total_customer_orders,
    p.avg_retail_price,
    p.distinct_customers,
    CASE 
        WHEN p.total_customer_orders > 1000 THEN 'High Sales'
        ELSE 'Low Sales'
    END AS sales_category,
    CONCAT('Part: ', p.p_name, ' | Orders: ', COALESCE(p.total_customer_orders, 0)) AS summary
FROM 
    AggregatedResults p
ORDER BY 
    p.avg_retail_price DESC NULLS LAST, p.total_customer_orders DESC;
