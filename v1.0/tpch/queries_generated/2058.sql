WITH TotalSales AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY o.o_orderkey
),
BestSuppliers AS (
    SELECT 
        ps.s_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 100.00
    GROUP BY ps.s_suppkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 500.00
    GROUP BY c.c_custkey
    HAVING COUNT(DISTINCT o.o_orderkey) > 10
),
RegionPerformance AS (
    SELECT 
        n.n_regionkey,
        SUM(ts.total_revenue) AS regional_revenue,
        COUNT(DISTINCT hc.c_custkey) AS high_value_customers_count
    FROM TotalSales ts
    JOIN orders o ON ts.o_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN HighValueCustomers hc ON c.c_custkey = hc.c_custkey
    GROUP BY n.n_regionkey
)
SELECT 
    r.r_name,
    rp.regional_revenue,
    rp.high_value_customers_count,
    COALESCE(bs.total_supplycost, 0) as total_supplycost
FROM region r
LEFT JOIN RegionPerformance rp ON r.r_regionkey = rp.n_regionkey
LEFT JOIN BestSuppliers bs ON rp.high_value_customers_count > 0
ORDER BY rp.regional_revenue DESC, r.r_name;
