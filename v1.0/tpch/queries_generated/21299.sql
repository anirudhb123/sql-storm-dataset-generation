WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER(PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
AvailableParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        (SELECT AVG(l.l_extendedprice) 
         FROM lineitem l 
         WHERE l.l_partkey = ps.ps_partkey AND l.l_shipdate >= '2023-01-01') AS avg_extended_price
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
),
SupplierNation AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    COALESCE(n.n_name, 'No Nation') AS nation_name,
    rp.rank AS supplier_rank,
    ap.ps_availqty,
    ap.avg_extended_price,
    hvo.total_value,
    CASE 
        WHEN hvo.total_value IS NOT NULL THEN 'High Value Order'
        ELSE 'Regular Order'
    END AS order_type
FROM part p
LEFT JOIN AvailableParts ap ON p.p_partkey = ap.ps_partkey
LEFT JOIN RankedSuppliers rp ON ap.ps_suppkey = rp.s_suppkey
LEFT JOIN nation n ON rp.s_nationkey = n.n_nationkey
LEFT JOIN HighValueOrders hvo ON hvo.o_orderkey = (
    SELECT MIN(o.o_orderkey) 
    FROM orders o 
    WHERE o.o_orderkey IN (
        SELECT DISTINCT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey
    )
)
WHERE (ap.ps_availqty IS NOT NULL AND ap.ps_availqty > 10)
   OR (rp.rank IS NULL OR rp.rank > 5)
ORDER BY p.p_partkey, rp.rank DESC
LIMIT 100;
