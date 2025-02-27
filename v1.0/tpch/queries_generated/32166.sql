WITH RECURSIVE OrderDates AS (
    SELECT o_orderdate, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT DATE_ADD(od.o_orderdate, INTERVAL 1 DAY), level + 1
    FROM OrderDates od
    JOIN orders o ON o.o_orderdate > od.o_orderdate AND o.o_orderstatus = 'O'
    WHERE level < 30
),
CustomerSummary AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= (SELECT DATE_SUB(CURDATE(), INTERVAL 1 YEAR))
    GROUP BY c.c_custkey
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        RANK() OVER (ORDER BY AVG(l.l_extendedprice) DESC) AS price_rank
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey
),
FinalSelection AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        cs.total_spent,
        cs.order_count,
        sp.total_supply_cost,
        rp.p_name,
        rp.price_rank
    FROM CustomerSummary cs
    JOIN SupplierPartDetails sp ON cs.total_spent IS NOT NULL
    LEFT JOIN RankedParts rp ON cs.order_count > 5
    WHERE sp.total_supply_cost > 10000
    ORDER BY total_spent DESC
)

SELECT 
    fs.c_name,
    fs.total_spent,
    fs.order_count,
    fs.total_supply_cost,
    fs.p_name,
    fs.price_rank
FROM FinalSelection fs
WHERE fs.price_rank <= 5
  AND fs.total_spent IS NOT NULL
  AND fs.total_supply_cost IS NOT NULL
  AND fs.order_count > 0
ORDER BY fs.total_spent DESC;
