WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM orders o
    WHERE o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1997-01-01'
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_comment NOT LIKE '%deprecated%')
    AND s.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps
        JOIN part p ON ps.ps_partkey = p.p_partkey
        WHERE p.p_retailprice < (SELECT AVG(p2.p_retailprice) FROM part p2)
    )
),
TotalLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1998-01-01'
    GROUP BY l.l_orderkey
),
HighlyRatedProducts AS (
    SELECT 
        p.p_partkey,
        p.p_mfgr,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_mfgr
    HAVING AVG(ps.ps_supplycost) < (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2 WHERE ps2.ps_availqty > 100)
),
FinalSelection AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        ns.n_name AS supplier_nation,
        COALESCE(SUM(t.total_revenue), 0) AS total_revenue,
        p.p_name,
        p.p_retailprice
    FROM RankedOrders o
    LEFT JOIN TotalLineItems t ON o.o_orderkey = t.l_orderkey
    LEFT JOIN FilteredSuppliers fs ON fs.s_suppkey = 
          (SELECT ps.ps_suppkey 
           FROM partsupp ps 
           WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM HighlyRatedProducts p) 
           LIMIT 1)
    LEFT JOIN nation ns ON fs.s_nationkey = ns.n_nationkey
    JOIN part p ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = fs.s_suppkey)
    WHERE o.rnk = 1
    GROUP BY o.o_orderkey, o.o_orderstatus, ns.n_name, p.p_name, p.p_retailprice
)
SELECT 
    *
FROM FinalSelection
WHERE total_revenue > (SELECT AVG(total_revenue) FROM FinalSelection)
ORDER BY total_revenue DESC
FETCH FIRST 10 ROWS ONLY;
