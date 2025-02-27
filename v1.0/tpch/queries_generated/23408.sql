WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_order
    FROM orders o
), SupplierPartPrices AS (
    SELECT 
        p.p_partkey,
        s.s_suppkey,
        ps.ps_supplycost,
        p.p_retailprice,
        (ps.ps_supplycost - p.p_retailprice) AS price_diff
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 100
), OrderLineAggregates AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(DISTINCT l.l_partkey) AS unique_parts,
        AVG(l.l_quantity) AS avg_quantity
    FROM lineitem l
    GROUP BY l.l_orderkey
), ExcludedNation AS (
    SELECT n.n_nationkey
    FROM nation n
    WHERE n.n_name LIKE '%land%' OR n.n_comment IS NULL
), CustomerStatus AS (
    SELECT 
        c.c_custkey,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'No Balance'
            WHEN c.c_acctbal < 0 THEN 'Negative Balance'
            ELSE 'Positive Balance'
        END AS balance_status
    FROM customer c
), Alerts AS (
    SELECT 
        DISTINCT so.o_orderkey,
        CONCAT('Order ', so.o_orderkey, ' has a status of ', so.o_orderstatus) AS alert_message
    FROM RankedOrders so
    WHERE so.rank_order <= 5 AND so.o_orderstatus = 'F' 
)

SELECT 
    coalesce(ct.cust_key, 0) AS cust_key,
    ss.p_partkey,
    ss.ps_supplycost,
    ss.price_diff,
    o_order.o_orderdate,
    o_order.total_value,
    cs.balance_status,
    al.alert_message
FROM SupplierPartPrices ss
FULL OUTER JOIN OrderLineAggregates o_order ON ss.p_partkey = o_order.l_orderkey
LEFT JOIN CustomerStatus cs ON cs.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name = 'Acme Corp')  -- Correlated Subquery
LEFT JOIN Alerts al ON al.o_orderkey = o_order.l_orderkey
LEFT JOIN ExcludedNation en ON en.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o_order.l_orderkey) -- Correlated Subquery
WHERE ss.price_diff IS NOT NULL 
  AND (ss.ps_supplycost BETWEEN 10 AND 100)
  AND o_order.total_value >= 5000
  AND cs.balance_status <> 'Negative Balance'
ORDER BY coalesce(o_order.total_value, 0) DESC, cs.balance_status, al.alert_message;
