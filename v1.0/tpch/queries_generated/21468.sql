WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
TopCustomers AS (
    SELECT 
        cust.c_custkey,
        cust.c_name,
        COALESCE(cust.total_spent, 0) AS total_spent,
        CASE 
            WHEN cust.total_orders = 0 THEN 'No Orders'
            ELSE CAST(cust.total_orders AS VARCHAR) || ' Orders' 
        END AS order_info
    FROM 
        CustomerOrders cust
    WHERE 
        cust.spending_rank <= 10
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        COUNT(ps.ps_partkey) AS parts_supplied,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        CASE 
            WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) IS NULL THEN 'No Sales'
            ELSE FORMAT(SUM(l.l_extendedprice * (1 - l.l_discount)), 'C')
        END AS formatted_sales
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    tc.c_name AS customer_name,
    tc.total_spent,
    tc.order_info,
    sp.s_name AS supplier_name,
    sp.parts_supplied,
    sp.formatted_sales
FROM 
    TopCustomers tc
FULL OUTER JOIN 
    SupplierPerformance sp ON tc.c_custkey = sp.s_suppkey
WHERE 
    (tc.total_spent > 500 OR sp.parts_supplied IS NULL)
    AND tc.total_orders IS NOT NULL
ORDER BY 
    tc.total_spent DESC NULLS LAST, 
    sp.total_sales ASC NULLS FIRST
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
