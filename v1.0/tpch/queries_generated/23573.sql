WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM orders o
    WHERE o.o_orderdate >= '1995-01-01' AND o.o_orderdate < '1996-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(NULLIF(s.s_comment, ''), 'No comments') AS normalized_comment,
        SUM(ps.ps_supplycost) AS total_supplycost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_comment
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 0
    GROUP BY c.c_custkey, c.c_name
),
OuterJoinExample AS (
    SELECT 
        c.c_name AS customer_name,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
    GROUP BY c.c_name
)
SELECT 
    r.o_orderkey,
    r.o_totalprice,
    r.o_orderstatus,
    COALESCE(sd.normalized_comment, 'No Supplier') AS supplier_comment,
    cs.total_orders,
    cs.total_spent,
    cs.last_order_date,
    oe.total_revenue,
    oe.order_count,
    CASE 
        WHEN r.o_orderstatus = 'F' THEN 'Finished'
        WHEN r.o_orderstatus IS NULL THEN 'Unknown Status'
        ELSE 'In Progress' 
    END AS order_status_description
FROM RankedOrders r
LEFT JOIN SupplierDetails sd ON sd.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey = (
        SELECT l.l_partkey 
        FROM lineitem l 
        WHERE l.l_orderkey = r.o_orderkey
        LIMIT 1
    )
    LIMIT 1
)
LEFT JOIN CustomerSummary cs ON cs.total_orders > 0
LEFT JOIN OuterJoinExample oe ON oe.customer_name = cs.c_name
WHERE r.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
ORDER BY r.o_totalprice DESC, r.o_orderdate ASC
LIMIT 100;
