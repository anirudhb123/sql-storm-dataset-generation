WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
),
SupplierPartStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT s.s_name) AS unique_suppliers,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
),
CustomerOrderCounts AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_totalprice) AS max_spent,
        MIN(o.o_totalprice) AS min_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING COUNT(o.o_orderkey) > 5
),
FinalResult AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        ros.o_orderkey,
        ros.o_totalprice,
        sps.total_available,
        sps.unique_suppliers,
        ccs.order_count,
        ccs.max_spent,
        COALESCE(ccs.min_spent, 0) AS min_spent_value
    FROM part p
    LEFT JOIN RankedOrders ros ON ros.o_orderkey = (
        SELECT MIN(o_orderkey)
        FROM RankedOrders
        WHERE order_rank <= 10 AND o_orderstatus = 'F'
    )
    LEFT JOIN SupplierPartStats sps ON p.p_partkey = sps.ps_partkey
    LEFT JOIN CustomerOrderCounts ccs ON ccs.order_count > 5
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    OR (p.p_comment IS NULL AND p.p_size < 10)
    ORDER BY p.p_partkey DESC, sps.average_supply_cost, ccs.order_count DESC
    LIMIT 100
)
SELECT
    f.*,
    CASE 
        WHEN f.order_count IS NULL THEN 'No Orders'
        WHEN f.order_count BETWEEN 1 AND 5 THEN 'Low'
        ELSE 'High'
    END AS order_status_indicator,
    CASE
        WHEN f.max_spent IS NULL THEN 'No Spending'
        ELSE CONCAT('Spent ', f.max_spent)
    END AS spending_summary
FROM FinalResult f
FULL OUTER JOIN nation n ON f.order_count = n.n_nationkey
WHERE n.n_nationkey IS NOT NULL OR f.order_count IS NULL;
