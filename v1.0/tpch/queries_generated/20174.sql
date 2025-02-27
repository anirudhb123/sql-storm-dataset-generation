WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'No Account'
            WHEN s.s_acctbal < 1000 THEN 'Low Balance'
            ELSE 'Healthy'
        END AS account_status,
        RANK() OVER (PARTITION BY CASE 
                                       WHEN s.s_acctbal IS NULL THEN 'No Account'
                                       WHEN s.s_acctbal < 1000 THEN 'Low Balance'
                                       ELSE 'Healthy'
                                   END ORDER BY s.s_acctbal DESC) AS rank_within_status
    FROM supplier s
),
PartSupplierStats AS (
    SELECT 
        p.p_partkey,
        COUNT(ps.ps_suppkey) AS total_suppliers,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        MAX(ps.ps_availqty) AS max_avail_qty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    nd.s_name,
    nd.account_status,
    p.p_name AS part_name,
    ps.total_suppliers,
    ps.avg_supply_cost,
    ps.max_avail_qty,
    co.c_name AS customer_name,
    co.order_count,
    co.total_spent,
    co.last_order_date
FROM SupplierDetails nd
LEFT JOIN PartSupplierStats ps ON nd.s_suppkey IN (
    SELECT ps_suppkey
    FROM partsupp
    WHERE ps_availqty > 100
)
JOIN lineitem l ON l.l_suppkey = nd.s_suppkey
JOIN CustomerOrders co ON co.c_custkey = (
    SELECT o.o_custkey
    FROM orders o
    WHERE o.o_orderkey = l.l_orderkey
)
WHERE nd.rank_within_status <= 5
    AND ps.total_suppliers > 0
    AND (l.l_discount IS NULL OR l.l_discount < 0.1)
    AND co.last_order_date > CURRENT_DATE - INTERVAL '1 year'
ORDER BY nd.account_status, co.total_spent DESC;
