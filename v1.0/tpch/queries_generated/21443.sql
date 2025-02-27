WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '1996-01-01' 
      AND o.o_orderdate < '1997-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(CASE WHEN ps.ps_availqty IS NULL THEN 0 ELSE ps.ps_availqty END) AS total_available,
        AVG(CASE WHEN ps.ps_supplycost IS NULL THEN 0 ELSE ps.ps_supplycost END) AS avg_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.total_available,
        sd.avg_supply_cost,
        nt.n_name
    FROM SupplierDetails sd
    JOIN nation nt ON sd.s_nationkey = nt.n_nationkey
    WHERE sd.total_available > 1000
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    ts.s_name,
    SUM(CASE WHEN l.l_discount > 0.10 THEN l.l_extendedprice * (1 - l.l_discount) END) AS discounted_price,
    COUNT(DISTINCT l.l_partkey) AS part_count,
    COALESCE(NULLIF(AVG(l.l_tax), 0), 'No tax records available') AS average_tax
FROM RankedOrders o
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE o.order_rank = 1
GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice, ts.s_name
HAVING SUM(l.l_quantity) > 50
   OR ORDER BY o.o_totalprice DESC
   LIMIT 100;
