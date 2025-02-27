WITH RECURSIVE NationHierarchy AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, 1 AS depth
    FROM nation n
    WHERE n.n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.depth + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
AggregatedSales AS (
    SELECT 
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY c.c_name
),
SupplierDetails AS (
    SELECT 
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name
),
TopCustomers AS (
    SELECT c.c_name, cs.total_sales, cs.order_count,
           RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM AggregatedSales cs
    WHERE cs.order_count > 5
),
MaxSuppliedParts AS (
    SELECT MAX(supplied_parts) AS max_parts FROM SupplierDetails
)
SELECT 
    th.c_name AS customer_name,
    th.total_sales,
    th.order_count,
    sd.s_name AS supplier_name,
    sd.supplied_parts,
    sd.avg_supply_cost,
    nh.n_name AS nation_name,
    nh.depth
FROM TopCustomers th
LEFT JOIN SupplierDetails sd ON th.order_count < sd.supplied_parts
JOIN NationHierarchy nh ON nh.n_nationkey = (SELECT c_nationkey FROM customer WHERE c_name = th.c_name LIMIT 1)
WHERE sd.supplied_parts = (SELECT max_parts FROM MaxSuppliedParts)
AND th.total_sales IS NOT NULL
ORDER BY th.total_sales DESC, sd.avg_supply_cost ASC;
