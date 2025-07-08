
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        o.o_orderdate,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= '1995-01-01' AND o.o_orderstatus = 'F'
),
TotalOrderValue AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY o.o_orderkey
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
NationSupplier AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(ss.avg_supply_cost) AS total_avg_cost
    FROM nation n
    JOIN SupplierStats ss ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = ss.s_suppkey)
    GROUP BY n.n_nationkey, n.n_name
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(NULLIF(p.p_comment, ''), 'No Comment') AS display_comment
    FROM part p
    WHERE p.p_size BETWEEN 10 AND 30
)
SELECT 
    R.o_orderkey,
    R.c_name,
    R.o_orderdate,
    T.total_value,
    P.p_name,
    N.n_name,
    N.total_avg_cost
FROM RankedOrders R
JOIN TotalOrderValue T ON R.o_orderkey = T.o_orderkey
LEFT JOIN lineitem L ON R.o_orderkey = L.l_orderkey
LEFT JOIN PartDetails P ON L.l_partkey = P.p_partkey
FULL OUTER JOIN NationSupplier N ON (R.price_rank = 1 AND N.total_avg_cost IS NOT NULL)
WHERE (T.total_value > 1000 OR N.n_name IS NULL)
  AND (T.total_value = 1500 OR P.p_retailprice > 50.00)
ORDER BY R.o_orderdate DESC, T.total_value DESC;
