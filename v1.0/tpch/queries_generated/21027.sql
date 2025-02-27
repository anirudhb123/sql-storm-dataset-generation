WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
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
        co.total_spent,
        co.order_count,
        RANK() OVER (ORDER BY co.total_spent DESC) AS customer_rank
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    WHERE 
        co.order_count > 0
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
SalesData AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    tc.cust_name,
    COALESCE(ss.s_name, 'No Supplier') AS supplier_name,
    sd.n_name AS nation,
    tc.total_spent,
    sd.total_sales,
    ss.avg_supply_cost,
    COUNT(DISTINCT l.l_orderkey) AS line_item_count,
    CASE 
        WHEN sd.total_sales > 1000000 THEN 'High Sales'
        WHEN sd.total_sales BETWEEN 500000 AND 1000000 THEN 'Medium Sales'
        ELSE 'Low Sales' 
    END AS sales_category,
    CASE 
        WHEN ss.total_available IS NULL THEN 'Supplier Data Missing'
        ELSE ROUND(ss.avg_supply_cost, 2)
    END AS average_supply_cost
FROM 
    TopCustomers tc
FULL OUTER JOIN 
    SupplierStats ss ON tc.cust_name = ss.s_name
JOIN 
    SalesData sd ON sd.nation = tc.n_natiname
LEFT JOIN 
    lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = tc.c_custkey)
WHERE 
    tc.customer_rank <= 10 
ORDER BY 
    tc.total_spent DESC, 
    sd.total_sales DESC
LIMIT 50 OFFSET 0;
