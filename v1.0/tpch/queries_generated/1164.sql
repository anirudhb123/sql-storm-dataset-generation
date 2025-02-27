WITH CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
    GROUP BY c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        cs.total_sales,
        cs.order_count
    FROM CustomerSales cs
    JOIN customer c ON cs.c_custkey = c.c_custkey
    WHERE cs.rank <= 5
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_name
)
SELECT 
    tc.c_name,
    tc.total_sales,
    spd.s_name,
    spd.total_available,
    CASE 
        WHEN tc.total_sales > 20000 THEN 'High Value'
        WHEN tc.total_sales BETWEEN 10000 AND 20000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category,
    COALESCE(spd.avg_supply_cost, 0) AS avg_supply_cost
FROM TopCustomers tc
LEFT JOIN SupplierPartDetails spd ON spd.ps_partkey IN (
    SELECT ps_partkey FROM partsupp WHERE ps_availqty > 50
) 
ORDER BY tc.total_sales DESC, spd.avg_supply_cost ASC
