WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey, r_name, r_comment
    FROM region
    WHERE r_regionkey = 0
    UNION ALL
    SELECT r.r_regionkey, r.r_name, r.r_comment
    FROM region r
    INNER JOIN RegionHierarchy rh ON r.r_regionkey = rh.r_regionkey + 1
),
TotalSales AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
    GROUP BY c.c_custkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ts.total_sales,
        ROW_NUMBER() OVER (ORDER BY ts.total_sales DESC) AS sales_rank
    FROM customer c
    JOIN TotalSales ts ON c.c_custkey = ts.c_custkey
    WHERE c.c_acctbal > 0
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        (ps.ps_availqty * ps.ps_supplycost) AS total_cost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY total_cost DESC) AS cost_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    rh.r_name AS region_name,
    tc.c_name AS customer_name,
    psi.p_name AS part_name,
    psi.total_cost,
    psi.ps_availqty,
    tc.total_sales,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM RegionHierarchy rh
LEFT JOIN TopCustomers tc ON tc.c_custkey IN (
    SELECT c.c_custkey 
    FROM customer c 
    WHERE c.c_nationkey IN (
        SELECT n.n_nationkey 
        FROM nation n 
        WHERE n.n_regionkey = rh.r_regionkey
    )
)
LEFT JOIN PartSupplierInfo psi ON psi.cost_rank = 1
ORDER BY rh.r_name, tc.total_sales DESC, psi.total_cost ASC;
