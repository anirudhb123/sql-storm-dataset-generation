WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_availqty,
        MAX(ps.ps_supplycost) AS max_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        n.n_regionkey,
        SUM(c.c_acctbal) AS total_acctbal
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY c.c_custkey, n.n_regionkey
)
SELECT 
    CONCAT(c.c_name, ' from ', r.r_name) AS supplier_info,
    p.p_name,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS orders_count,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_order_value,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_qty,
    MAX(CASE WHEN l.l_shipdate IS NULL THEN 'Not Shipped' ELSE 'Shipped' END) AS shipping_status,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice) DESC) AS regional_rank
FROM part p
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN SupplierParts sp ON l.l_suppkey = sp.ps_suppkey
LEFT JOIN supplier s ON sp.ps_suppkey = s.s_suppkey
JOIN CustomerRegion cr ON s.s_suppkey = cr.c_custkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN RankedOrders o ON o.o_orderkey = l.l_orderkey
WHERE o.price_rank <= 5
GROUP BY r.r_name, c.c_name, p.p_name, s.s_name
HAVING SUM(l.l_quantity) > 10 OR COUNT(DISTINCT o.o_orderkey) > 2
ORDER BY regional_rank ASC, orders_count DESC;
