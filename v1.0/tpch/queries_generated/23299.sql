WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) as rank
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'No Balance' 
            WHEN s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) THEN 'Above Average' 
            ELSE 'Below Average' 
        END as balance_status
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CriticalLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_price,
        COUNT(*) AS item_count
    FROM lineitem l
    WHERE l.l_returnflag = 'N' AND l.l_linestatus = 'O'
    GROUP BY l.l_orderkey
)
SELECT 
    r.o_orderkey,
    COALESCE(s.s_name, 'Unknown') AS supplier_name,
    p.p_name,
    d.total_supply_cost,
    li.net_price,
    SUM(CASE WHEN li.item_count > 5 THEN 1 ELSE 0 END) OVER (PARTITION BY r.o_orderkey) as high_item_count_flag,
    CASE 
        WHEN d.total_supply_cost IS NULL THEN 'Cost Unknown'
        ELSE 'Cost Available'
    END as cost_availability,
    ROW_NUMBER() OVER (ORDER BY r.o_orderdate DESC, p.p_name) AS order_rank
FROM RankedOrders r
FULL OUTER JOIN SupplierInfo s ON r.o_orderkey = s.s_suppkey AND r.rank = 1
LEFT JOIN PartDetails d ON s.s_suppkey = d.p_partkey
LEFT JOIN CriticalLineItems li ON r.o_orderkey = li.l_orderkey
WHERE (s.balance_status = 'Above Average' OR d.total_supply_cost IS NOT NULL)
    AND (r.o_orderstatus IS NOT NULL)
ORDER BY r.o_orderdate DESC, p.p_name ASC;
