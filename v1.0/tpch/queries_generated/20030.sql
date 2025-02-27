WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_order
    FROM orders o
),
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING SUM(s.s_acctbal) > (SELECT AVG(s_acctbal) FROM supplier)
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(ps.ps_availqty, 0) AS available_quantity,
        (CASE 
            WHEN ps.ps_supplycost IS NULL THEN 'Unknown Cost' 
            ELSE CAST(ps.ps_supplycost AS VARCHAR)
         END) AS supply_cost_info
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS total_items,
        AVG(l.l_discount) AS average_discount,
        MIN(l.l_shipdate) AS earliest_shipdate
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
)
SELECT 
    p.p_name,
    ns.n_name AS supplier_nation,
    o.o_orderdate,
    ro.rank_order,
    CASE 
        WHEN li.total_revenue IS NULL THEN 'No Revenue'
        ELSE CAST(li.total_revenue AS VARCHAR)
    END AS revenue_status,
    li.total_items,
    li.average_discount,
    pd.available_quantity,
    pd.supply_cost_info
FROM PartSupplierDetails pd
JOIN RankedOrders ro ON pd.ps_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = (SELECT TOP 1 s.s_suppkey FROM supplier s WHERE s.s_acctbal > 1000 ORDER BY s.s_acctbal DESC))
JOIN orders o ON o.o_orderkey = ro.o_orderkey
JOIN TopNations ns ON ns.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
LEFT JOIN LineItemDetails li ON li.l_orderkey = o.o_orderkey
WHERE pd.p_retailprice BETWEEN 50 AND 200
  AND (o.o_orderstatus IN ('O', 'P') OR o.o_orderdate > '2023-01-01')
  AND NOT EXISTS (SELECT 1 FROM lineitem l WHERE l.l_orderkey = o.o_orderkey AND l.l_discount > 0.05)
ORDER BY ro.rank_order, ns.total_acctbal DESC, o.o_orderdate DESC;
