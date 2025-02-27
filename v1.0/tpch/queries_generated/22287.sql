WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
), FilteredParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_size,
        SUM(ps.ps_availqty) AS total_available_qty,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > (
        SELECT AVG(p1.p_retailprice)
        FROM part p1
        WHERE p1.p_size < 10
    )
    GROUP BY p.p_partkey, p.p_name, p.p_size
), DetailedLineItems AS (
    SELECT
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        (l.l_extendedprice * (1 - l.l_discount)) AS net_price,
        CASE
            WHEN l.l_returnflag = 'R' THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status
    FROM lineitem l
    WHERE l.l_shipdate <= CURRENT_DATE - INTERVAL '7 days'
    AND l.l_tax IS NOT NULL
), RegionSupplier AS (
    SELECT
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_account_balance
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
), OrderDetails AS (
    SELECT
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        r.name AS customer_name,
        li.l_partkey,
        li.net_price,
        li.return_status,
        rp.total_available_qty,
        rs.region_name,
        rs.supplier_count AS region_supplier_count
    FROM RankedOrders ro
    JOIN DetailedLineItems li ON ro.o_orderkey = li.l_orderkey
    JOIN FilteredParts rp ON li.l_partkey = rp.p_partkey
    JOIN region r ON r.r_regionkey = (
        SELECT n.n_regionkey
        FROM nation n
        JOIN customer c ON n.n_nationkey = c.c_nationkey
        WHERE c.c_name = ro.c_name
    )
    JOIN RegionSupplier rs ON r.r_name = rs.region_name
    WHERE ro.order_rank = 1
)

SELECT
    od.*,
    CASE
        WHEN od.total_available_qty IS NULL THEN 'Insufficient Inventory'
        ELSE 'Sufficient Inventory'
    END AS inventory_status
FROM OrderDetails od
ORDER BY od.o_totalprice DESC
LIMIT 50 OFFSET 10;

-- A bizarre and unusual semantic choice: a derived table is not used here 
-- and demonstrates NULL logic in aggregating supplier accounts. 
-- Obscure filtering on return flags accompanied by a window function leads to unique insights.
