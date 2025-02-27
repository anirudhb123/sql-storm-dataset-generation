WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 50000
), 
HighValueOrders AS (
    SELECT 
        o.o_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM orders o
    WHERE o.o_orderdate >= '2021-01-01'
    GROUP BY o.o_custkey
    HAVING SUM(o.o_totalprice) > 100000
), 
SupplierParts AS (
    SELECT 
        p.p_partkey, 
        p.p_brand, 
        s.s_suppkey, 
        ps.ps_availqty,
        ps.ps_supplycost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_retailprice > 20.00 AND ps.ps_availqty IS NOT NULL
)

SELECT 
    nc.n_name AS nation_name,
    COUNT(DISTINCT rc.c_custkey) AS high_value_customers,
    SUM(sp.ps_supplycost * sp.ps_availqty) AS total_supply_cost,
    AVG(hv.total_spent) AS avg_high_value_spent
FROM RankedCustomers rc
JOIN nation nc ON rc.c_nationkey = nc.n_nationkey
LEFT JOIN HighValueOrders hv ON rc.c_custkey = hv.o_custkey
JOIN SupplierParts sp ON hv.o_custkey = rc.c_custkey AND sp.rank = 1
WHERE nc.n_name IS NOT NULL
GROUP BY nc.n_name
ORDER BY total_supply_cost DESC 
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
