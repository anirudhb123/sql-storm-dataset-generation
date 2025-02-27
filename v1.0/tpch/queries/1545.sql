WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerStatistics AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
MostActiveCustomers AS (
    SELECT
        cs.c_custkey,
        cs.total_spent,
        ROW_NUMBER() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM CustomerStatistics cs
    WHERE cs.order_count > 5  
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT cs.c_custkey) AS active_customers,
    AVG(ss.total_supply_cost) AS avg_supplier_cost,
    COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN MostActiveCustomers cs ON cs.c_custkey = c.c_custkey
LEFT JOIN SupplierSummary ss ON ss.s_suppkey = (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey IN (SELECT ps_partkey FROM part WHERE p_size > 10)
    LIMIT 1
)
LEFT JOIN partsupp ps ON ps.ps_suppkey = ss.s_suppkey
WHERE n.n_name IS NOT NULL
GROUP BY n.n_name
HAVING COUNT(DISTINCT cs.c_custkey) > 0;