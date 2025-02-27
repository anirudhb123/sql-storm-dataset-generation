WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_totalprice, o_orderdate, o_custkey
    FROM orders
    WHERE o_orderstatus = 'F' -- Filter for finalized orders
    UNION ALL
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_custkey
    FROM orders o
    INNER JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey + 1 -- Recursion condition simulating an order sequence
),
CustomerSummary AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
),
SupplierSummary AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
PartMetrics AS (
    SELECT p.p_partkey, p.p_name, p.p_size, p.p_retailprice,
           ROW_NUMBER() OVER (ORDER BY p.p_retailprice DESC) AS price_rank,
           SUM(l.l_quantity) AS total_quantity
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_size, p.p_retailprice
)
SELECT 
    cus.c_name AS customer_name,
    cus.total_spent,
    supp.total_supply_cost,
    part.p_name AS part_name,
    part.total_quantity,
    CASE 
        WHEN cus.total_spent IS NULL THEN 'No Orders'
        WHEN supp.total_supply_cost IS NULL THEN 'No Supplies'
        ELSE 'Active'
    END AS status,
    ROW_NUMBER() OVER (PARTITION BY cus.c_custkey ORDER BY part.total_quantity DESC) AS customer_part_rank
FROM CustomerSummary cus
FULL OUTER JOIN SupplierSummary supp ON cus.c_custkey = supp.ps_partkey
JOIN PartMetrics part ON part.price_rank <= 10
WHERE (cus.total_spent > 1000 OR supp.total_supply_cost IS NOT NULL)
ORDER BY cus.total_spent DESC, part.total_quantity DESC;
