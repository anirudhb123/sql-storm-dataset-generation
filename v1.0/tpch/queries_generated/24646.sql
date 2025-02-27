WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) AS total_rank,
        COUNT(*) OVER (PARTITION BY EXTRACT(MONTH FROM o.o_orderdate)) AS monthly_orders
    FROM orders o
), SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        AVG(CASE WHEN ps.ps_availqty IS NOT NULL THEN ps.ps_availqty ELSE 0 END) AS avg_availability
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), HighLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_price
    FROM lineitem l
    GROUP BY l.l_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(l_extendedprice) FROM lineitem)
), SelectedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        CASE 
            WHEN c.c_acctbal IS NULL OR c.c_acctbal < 0 THEN 'Negative or No Balance'
            ELSE 'Valid Balance'
        END AS account_status
    FROM customer c
    WHERE c.c_mktsegment IN ('BUILDING', 'FURNITURE')
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(ss.total_supplycost, 0) AS total_supplycost,
    COALESCE(ss.avg_availability, 0) AS avg_availability,
    lc.net_price,
    sc.c_name,
    IFNULL(sc.account_status, 'Unknown') AS account_status,
    ROW_NUMBER() OVER (PARTITION BY r.o_orderkey ORDER BY r.o_totalprice DESC) AS order_rank
FROM RankedOrders r
LEFT JOIN SupplierStats ss ON ss.total_supplycost = (SELECT MAX(total_supplycost) FROM SupplierStats)
JOIN HighLineItems lc ON r.o_orderkey = lc.l_orderkey
LEFT JOIN SelectedCustomers sc ON r.o_orderkey = (SELECT MAX(o_orderkey) FROM orders o WHERE o.o_custkey = sc.c_custkey)
WHERE r.total_rank <= 5
ORDER BY r.o_orderdate DESC, total_supplycost DESC;
