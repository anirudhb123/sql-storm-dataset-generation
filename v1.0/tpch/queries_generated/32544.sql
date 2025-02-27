WITH RECURSIVE SupplyChain AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_suppkey,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER(PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS supply_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER(PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name
    FROM CustomerOrders c
    WHERE c.total_spent > (
        SELECT AVG(total_spent) FROM CustomerOrders
    )
),
PartSupplyDetails AS (
    SELECT 
        sc.p_partkey,
        sc.p_name,
        sc.s_name,
        sc.ps_availqty,
        sc.ps_supplycost,
        COALESCE(NULLIF(sc.ps_supplycost, 0), 9999) AS effective_supplycost
    FROM SupplyChain sc
    LEFT JOIN HighValueCustomers hvc ON sc.ps_suppkey = (SELECT MIN(ps_suppkey) FROM SupplyChain WHERE p_partkey = sc.p_partkey)
)
SELECT 
    p.p_name,
    COUNT(DISTINCT sc.s_suppkey) AS supplier_count,
    AVG(sc.effective_supplycost) AS avg_supply_cost,
    SUM(CASE 
        WHEN c.order_count IS NULL THEN 0 
        ELSE 1 
    END) AS orders_from_high_value_customers
FROM part p
LEFT JOIN PartSupplyDetails sc ON p.p_partkey = sc.p_partkey
LEFT JOIN CustomerOrders c ON sc.s_name = (SELECT MIN(s_name) FROM supplier WHERE s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_partkey = p.p_partkey))
GROUP BY p.p_name
HAVING AVG(sc.effective_supplycost) > (
    SELECT AVG(effective_supplycost) FROM PartSupplyDetails
)
ORDER BY supplier_count DESC;
