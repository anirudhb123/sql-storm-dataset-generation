WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= '2022-01-01'
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
SupplierRegion AS (
    SELECT 
        n.n_name,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_name, r.r_name
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_available
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
)

SELECT 
    pd.p_partkey,
    pd.p_name,
    pd.p_retailprice,
    pd.total_available,
    sr.n_name AS supplier_nation,
    sr.r_name AS supplier_region,
    hv.total_spent,
    CASE 
        WHEN hv.total_spent IS NULL THEN 'No Purchase'
        ELSE 'High Value Customer'
    END AS customer_status
FROM PartDetails pd
LEFT JOIN SupplierRegion sr ON pd.total_available > 0
LEFT JOIN HighValueCustomers hv ON hv.c_custkey IN (
    SELECT DISTINCT o.o_custkey
    FROM RankedOrders ro
    JOIN orders o ON ro.o_orderkey = o.o_orderkey
    WHERE ro.price_rank <= 10
)
WHERE pd.p_retailprice > (SELECT AVG(p_retailprice) FROM part) 
  AND (pd.total_available > 100 OR pd.p_name LIKE 'S%')
ORDER BY pd.p_partkey;
