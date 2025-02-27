WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        AVG(l.l_extendedprice) AS avg_price,
        MAX(l.l_discount) AS max_discount
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
),
RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_size,
        ps.total_supply_cost,
        RANK() OVER (ORDER BY ps.total_supply_cost DESC) AS supply_rank
    FROM PartStats p
    JOIN SupplierSummary ps ON p.p_partkey = ps.s_suppkey
)
SELECT 
    cus.c_name AS customer_name,
    SUM(cus.total_spent) AS total_spent_by_customer,
    COUNT(ops.o_orderkey) AS total_orders,
    rp.p_name AS part_name,
    rp.p_size AS part_size,
    rp.supply_rank,
    ps.max_discount
FROM CustomerOrderSummary cus
LEFT JOIN orders ops ON cus.c_custkey = ops.o_custkey
LEFT JOIN RankedParts rp ON rp.p_partkey IN (
    SELECT ps.p_partkey 
    FROM PartStats ps 
    WHERE ps.avg_price < (SELECT AVG(avg_price) FROM PartStats)
)
JOIN PartStats ps ON ps.p_partkey = rp.p_partkey
WHERE cus.total_orders > 0
GROUP BY cus.c_name, rp.p_name, rp.p_size, rp.supply_rank, ps.max_discount
HAVING SUM(cus.total_spent) > 1000.00
ORDER BY total_spent_by_customer DESC, rp.supply_rank;
