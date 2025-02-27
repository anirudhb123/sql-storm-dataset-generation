WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice > 0
),
SupplierCounts AS (
    SELECT
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
ZeroSupply AS (
    SELECT 
        ps.ps_partkey,
        MAX(CASE WHEN ps.ps_availqty = 0 THEN 1 ELSE 0 END) AS is_zero_supply
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
DistinctOrderCustomer AS (
    SELECT DISTINCT
        o.o_custkey,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_num
    FROM orders o
    WHERE o.o_orderstatus = 'F'
)
SELECT
    np.n_name,
    rp.p_name,
    COALESCE(ps.supplier_count, 0) AS supplier_count,
    COALESCE(zs.is_zero_supply, 0) AS no_supply,
    COUNT(DISTINCT hvo.o_orderkey) AS high_value_order_count,
    SUM(CASE WHEN dr.order_num IS NOT NULL THEN 1 ELSE 0 END) AS distinct_orders
FROM region r
JOIN nation np ON r.r_regionkey = np.n_regionkey
LEFT JOIN RankedParts rp ON rp.price_rank <= 5
LEFT JOIN SupplierCounts ps ON rp.p_partkey = ps.ps_partkey
LEFT JOIN ZeroSupply zs ON rp.p_partkey = zs.ps_partkey
LEFT JOIN HighValueOrders hvo ON rp.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_availqty > 0)
LEFT JOIN DistinctOrderCustomer dr ON dr.o_custkey = np.n_nationkey
GROUP BY 
    np.n_name,
    rp.p_name
HAVING 
    (supplier_count > 2 OR no_supply = 1)
    AND (COUNT(DISTINCT hvo.o_orderkey) > 0 OR COUNT(DISTINCT dr.order_num) > 2)
ORDER BY 
    np.n_name, 
    rp.p_retailprice DESC NULLS LAST;
