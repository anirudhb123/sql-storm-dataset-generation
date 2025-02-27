WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderdate,
        o.o_totalprice,
        o.o_clerk,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate >= '1996-01-01')
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost ASC) AS price_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal IS NOT NULL
),
CustomerSpending AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 1000
),
OuterJoinExample AS (
    SELECT 
        r.r_name,
        n.n_name,
        SUM(COALESCE(ps.ps_availqty, 0)) AS total_avail_qty,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN orders o ON ps.ps_partkey = ANY (SELECT ps_partkey FROM partsupp GROUP BY ps_partkey HAVING SUM(ps_supplycost) > 50)
    GROUP BY r.r_name, n.n_name
),
FinalResult AS (
    SELECT
        r.r_name,
        SUM(CASE WHEN lo.l_returnflag = 'R' THEN lo.l_extendedprice * (1 - lo.l_discount) ELSE 0 END) AS returned_revenue,
        COUNT(DISTINCT c.c_custkey) AS active_customers,
        AVG(total_spent) AS avg_customer_spending
    FROM OuterJoinExample o
    JOIN CustomerSpending c ON o.order_count > 0
    LEFT JOIN lineitem lo ON lo.l_orderkey = ANY (SELECT o_orderkey FROM RankedOrders WHERE order_rank <= 10)
    GROUP BY r.r_name
)
SELECT 
    f.r_name,
    f.returned_revenue,
    f.active_customers,
    f.avg_customer_spending,
    CASE 
        WHEN f.avg_customer_spending IS NULL THEN 'No Data'
        WHEN f.avg_customer_spending > 500 THEN 'High Spending'
        WHEN f.avg_customer_spending BETWEEN 200 AND 500 THEN 'Moderate Spending'
        ELSE 'Low Spending'
    END AS spending_category
FROM FinalResult f
ORDER BY f.returned_revenue DESC, f.active_customers ASC
LIMIT 50;
