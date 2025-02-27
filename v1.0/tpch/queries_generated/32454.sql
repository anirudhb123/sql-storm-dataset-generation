WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS hierarchy_level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000 AND sh.hierarchy_level < 5
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        MAX(ps.ps_supplycost) AS highest_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.total_available,
        ps.highest_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    JOIN PartSupplier ps ON p.p_partkey = ps.ps_partkey
)

SELECT 
    c.c_name AS customer_name,
    c.total_spent,
    p.p_name AS part_name,
    p.p_retailprice,
    sh.hierarchy_level,
    CASE 
        WHEN c.total_spent > 10000 THEN 'VIP'
        WHEN c.total_spent BETWEEN 5000 AND 10000 THEN 'Regular'
        ELSE 'New'
    END AS customer_type,
    COALESCE(r.r_name, 'Unknown') AS region_name
FROM CustomerSummary c
LEFT JOIN TopParts p ON c.total_orders = p.price_rank
JOIN nation n ON n.n_nationkey = c.c_nationkey
LEFT JOIN region r ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
WHERE c.total_spent IS NOT NULL
AND p.total_available >= 10
AND p.p_retailprice IS NOT NULL
ORDER BY customer_name, part_name;
