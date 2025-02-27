
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '90 days'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueSuppliers AS (
    SELECT 
        si.s_suppkey,
        si.s_name
    FROM SupplierInfo si
    WHERE si.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierInfo)
),
OrderItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(*) AS item_count,
        COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS return_count
    FROM lineitem l
    GROUP BY l.l_orderkey
),
FinalReport AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        oi.total_price,
        oi.item_count,
        oi.return_count,
        hs.s_name AS supplier_name
    FROM RankedOrders ro
    LEFT JOIN OrderItems oi ON ro.o_orderkey = oi.l_orderkey
    LEFT JOIN HighValueSuppliers hs ON hs.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT DISTINCT l.l_partkey 
            FROM lineitem l 
            WHERE l.l_orderkey = ro.o_orderkey
        )
    )
    WHERE ro.order_rank = 1
)
SELECT 
    fr.o_orderkey,
    fr.o_orderdate,
    fr.total_price AS order_total_price,
    fr.item_count,
    COALESCE(fr.return_count, 0) AS order_return_count,
    COALESCE(fr.supplier_name, 'Unknown Supplier') AS supplier_name
FROM FinalReport fr
ORDER BY fr.o_orderdate DESC, fr.total_price DESC
LIMIT 50;
