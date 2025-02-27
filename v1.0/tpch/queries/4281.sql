WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM supplier s
),
CustomerOrderTotals AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
),
PartSupplierAggregates AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)

SELECT 
    p.p_name, 
    ps.total_available_qty, 
    ps.total_supply_cost, 
    COALESCE(cs.total_spent, 0) AS total_spent_by_customer,
    CASE 
        WHEN ps.total_available_qty > 100 THEN 'High Availability'
        WHEN ps.total_available_qty BETWEEN 50 AND 100 THEN 'Medium Availability'
        ELSE 'Low Availability' 
    END AS availability_status,
    RANK() OVER (ORDER BY COALESCE(cs.total_spent, 0) DESC) AS customer_spending_rank
FROM part p
LEFT JOIN PartSupplierAggregates ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN CustomerOrderTotals cs ON cs.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name LIKE 'Customer%' LIMIT 1)
JOIN RankedSuppliers r ON r.s_suppkey = (SELECT ps2.ps_suppkey FROM partsupp ps2 WHERE ps2.ps_partkey = p.p_partkey ORDER BY ps2.ps_supplycost DESC LIMIT 1)
WHERE r.supplier_rank <= 3
ORDER BY availability_status, total_spent_by_customer DESC;
