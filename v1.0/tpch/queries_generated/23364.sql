WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_totalprice IS NOT NULL
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
    HAVING SUM(ps.ps_availqty) > 0
),
HighValueNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING SUM(s.s_acctbal) > 100000
),
FinalData AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(RC.completed_order_count, 0) AS completed_order_count,
        COALESCE(SA.total_avail_qty, 0) AS available_quantity,
        COALESCE(NA.total_acctbal, 0) AS nation_acctbal,
        CASE 
            WHEN p.p_retailprice > 0 THEN ROUND((p.p_retailprice * 1.15), 2) 
            ELSE NULL 
        END AS adjusted_price
    FROM part p
    LEFT JOIN (
        SELECT 
            o.o_clerk,
            COUNT(o.o_orderkey) AS completed_order_count 
        FROM orders o
        WHERE o.o_orderstatus = 'F'
        GROUP BY o.o_clerk
    ) RC ON p.p_partkey = RC.o_orderkey
    LEFT JOIN SupplierAvailability SA ON p.p_partkey = SA.ps_partkey
    LEFT JOIN HighValueNations NA ON p.p_partkey = NA.n_nationkey
)
SELECT 
    FD.p_partkey,
    FD.p_name,
    FD.completed_order_count,
    FD.available_quantity,
    FD.nation_acctbal,
    FD.adjusted_price
FROM FinalData FD
WHERE FD.adjusted_price IS NOT NULL
  AND (FD.available_quantity > 0 OR FD.nation_acctbal > 50000)
ORDER BY FD.completed_order_count DESC, FD.available_quantity ASC
LIMIT 10;
