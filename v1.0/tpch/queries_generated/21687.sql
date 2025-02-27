WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS ranking,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),

TopSuppliers AS (
    SELECT *
    FROM RankedSuppliers
    WHERE ranking = 1
),

CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),

HighlyValuedCustomers AS (
    SELECT 
        cust.c_custkey,
        cust.total_orders,
        cust.total_spent,
        RANK() OVER (ORDER BY cust.total_spent DESC) AS customer_rank
    FROM 
        CustomerOrderStats cust
    WHERE 
        cust.total_spent IS NOT NULL AND cust.total_orders > 10
),

FilteredOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        COALESCE(l.l_discount, 0) AS discount
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey AND l.l_returnflag = 'N'
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderstatus IN ('O', 'F')
),

FinalReport AS (
    SELECT 
        n.n_name AS nation,
        SUM(o.total_spent) AS total_revenue,
        COUNT(DISTINCT c.c_custkey) AS unique_customers,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(COALESCE(o.discount, 0)) AS total_discounts
    FROM 
        HighlyValuedCustomers c
    JOIN 
        nation n ON c.c_custkey IN (SELECT c.c_custkey FROM customer WHERE c.c_nationkey = n.n_nationkey)
    JOIN 
        FilteredOrders o ON c.c_custkey = o.o_orderkey
    GROUP BY 
        n.n_name
)

SELECT 
    f.nation,
    f.total_revenue,
    f.unique_customers,
    f.order_count,
    f.total_discounts,
    CASE 
        WHEN f.total_revenue IS NULL THEN 'No Revenue' 
        ELSE 'Revenue Generated' 
    END AS revenue_status,
    ROW_NUMBER() OVER (ORDER BY f.total_revenue DESC) AS revenue_rank
FROM 
    FinalReport f
WHERE 
    f.total_revenue IS NOT NULL
ORDER BY 
    f.total_revenue DESC;
