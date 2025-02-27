WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_orderstatus,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS status_rank,
        ROW_NUMBER() OVER (ORDER BY o.o_orderdate DESC) AS recency_rank
    FROM orders o
    WHERE o.o_totalprice > (
        SELECT AVG(o2.o_totalprice) 
        FROM orders o2 
        WHERE o2.o_orderdate >= DATEADD(month, -12, CURRENT_DATE)
    )
),
SuppliersWithHighBalance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal) 
        FROM supplier s2 
        WHERE s2.s_nationkey IN (
            SELECT n.n_nationkey 
            FROM nation n 
            WHERE n.n_regionkey = (
                SELECT r.r_regionkey 
                FROM region r 
                WHERE r.r_name = 'ASIA'
            )
        )
    )
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrderSummary AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 5000
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_orderstatus,
    r.o_totalprice,
    s.s_name AS supplier_name,
    s.s_acctbal AS supplier_balance,
    c.c_name AS customer_name,
    cs.total_spent,
    cs.order_count,
    CASE 
        WHEN r.status_rank > 5 THEN 'Medium Priority'
        ELSE 'High Priority'
    END AS order_priority
FROM RankedOrders r
LEFT JOIN SuppliersWithHighBalance s ON r.o_orderkey = s.s_suppkey
JOIN CustomerOrderSummary cs ON r.o_orderkey = cs.c_custkey
WHERE 
    (r.o_orderstatus = 'O' OR r.o_orderstatus = 'F') 
    AND (s.part_count > 10 AND cs.order_count > 0)
ORDER BY r.o_orderdate DESC, r.o_totalprice DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
