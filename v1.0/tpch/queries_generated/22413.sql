WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) as rn
    FROM part p
), 
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        p.p_partkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        s.s_name,
        s.s_acctbal,
        LEAST(s.s_acctbal, SUM(ps.ps_supplycost) OVER (PARTITION BY ps.ps_partkey)) AS min_acctbal
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
), 
SuspiciousOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'R' OR l.l_linenumber NOT IN (SELECT MAX(l2.l_linenumber) FROM lineitem l2 WHERE l2.l_orderkey = l.l_orderkey)
    GROUP BY o.o_orderkey
), 
AggregatedSuppliers AS (
    SELECT 
        spd.s_suppkey, 
        AVG(spd.ps_supplycost) AS avg_supplycost,
        COUNT(DISTINCT spd.p_partkey) AS part_count
    FROM SupplierPartDetails spd
    GROUP BY spd.s_suppkey
)
SELECT 
    np.n_name,
    rp.p_name,
    rp.p_retailprice,
    spd.s_name,
    spd.ps_availqty,
    CASE 
        WHEN spd.min_acctbal IS NULL THEN 'No Account Balance' 
        ELSE CAST(spd.min_acctbal AS VARCHAR) 
    END AS min_balance_or_null,
    so.total_price,
    CASE 
        WHEN so.total_price IS NULL THEN 'Suspicious' 
        ELSE 'Not Suspicious' 
    END AS order_status,
    AVG(as.avg_supplycost) OVER (PARTITION BY np.n_nationkey) AS avg_supply_cost_per_nation,
    coalesce((SELECT AVG(ps.ps_supplycost) FROM partsupp ps WHERE ps.ps_partkey NOT IN (SELECT p.p_partkey FROM part p WHERE p.p_size < 10)), 0) AS avg_supplycost_below_size_10
FROM 
    RankedParts rp
JOIN supplierpartdetails spd ON rp.p_partkey = spd.p_partkey
JOIN nation np ON np.n_nationkey = (
    SELECT DISTINCT s.n_nationkey 
    FROM supplier s WHERE s.s_suppkey = spd.s_suppkey
)
LEFT JOIN SuspiciousOrders so ON so.o_orderkey = (
    SELECT MAX(o.o_orderkey) FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = np.n_nationkey)
)
JOIN AggregatedSuppliers as ON spd.s_suppkey = as.s_suppkey
WHERE 
    rp.rn = 1 
    AND (spd.ps_availqty > 0 OR spd.s_acctbal < 100)
ORDER BY 
    rp.p_retailprice DESC, 
    np.n_name ASC;
