WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
  
    UNION ALL

    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
),
RankedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice,
        RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS price_rank
    FROM lineitem l
    WHERE l.l_discount > 0.1
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
FinalResults AS (
    SELECT 
        ch.o_orderkey,
        co.c_custkey,
        co.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_cost,
        COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) AS return_count,
        ss.total_supplycost
    FROM OrderHierarchy ch
    JOIN RankedLineItems l ON ch.o_orderkey = l.l_orderkey
    JOIN CustomerOrders co ON ch.o_custkey = co.c_custkey
    JOIN SupplierSummary ss ON l.l_suppkey = ss.s_suppkey
    GROUP BY ch.o_orderkey, co.c_custkey, co.c_name, ss.total_supplycost
    HAVING total_lineitem_cost > 1000
)
SELECT 
    o.o_orderkey,
    c.c_name,
    COALESCE(rr.order_count, 0) AS customer_order_count,
    fr.total_lineitem_cost,
    fr.return_count,
    fr.total_supplycost
FROM FinalResults fr
LEFT JOIN CustomerOrders rr ON fr.c_custkey = rr.c_custkey
JOIN orders o ON fr.o_orderkey = o.o_orderkey
JOIN customer c ON rr.c_custkey = c.c_custkey
WHERE o.o_orderstatus = 'O' OR o.o_orderdate IS NULL
ORDER BY fr.total_lineitem_cost DESC, fr.return_count ASC;
