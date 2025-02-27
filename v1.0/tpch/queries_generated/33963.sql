WITH RECURSIVE SupplyChain AS (
    SELECT
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_availqty,
        SUM(ps.ps_supplycost) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
RankedSuppliers AS (
    SELECT
        sc.ps_partkey,
        sc.ps_suppkey,
        sc.total_availqty,
        sc.total_supplycost,
        n.n_name,
        ROW_NUMBER() OVER (PARTITION BY sc.ps_partkey ORDER BY sc.total_availqty DESC) as supply_rank
    FROM SupplyChain sc
    JOIN supplier s ON sc.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        c.c_mktsegment
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_mktsegment
),
HighValueCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        c.total_spent,
        CASE 
            WHEN c.total_spent > 10000 THEN 'Gold'
            WHEN c.total_spent BETWEEN 5000 AND 10000 THEN 'Silver'
            ELSE 'Bronze'
        END AS customer_tier
    FROM CustomerOrders c
    WHERE c.order_count > 5
),
FinalAnalysis AS (
    SELECT 
        r.ps_partkey,
        r.ps_suppkey,
        r.total_availqty,
        COALESCE(hvc.c_name, 'No Orders') AS customer_name,
        COALESCE(hvc.customer_tier, 'None') AS customer_tier,
        r.total_supplycost
    FROM RankedSuppliers r
    LEFT JOIN HighValueCustomers hvc ON r.ps_suppkey = hvc.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    f.customer_name,
    f.customer_tier,
    SUM(f.total_availqty) AS total_available,
    AVG(f.total_supplycost) AS avg_supply_cost
FROM part p
LEFT JOIN FinalAnalysis f ON p.p_partkey = f.ps_partkey
GROUP BY p.p_partkey, p.p_name, f.customer_name, f.customer_tier
HAVING AVG(f.total_supply_cost) IS NOT NULL 
   AND SUM(f.total_available) > 100
ORDER BY p.p_partkey;
