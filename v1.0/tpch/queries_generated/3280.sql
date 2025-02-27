WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        s.s_name AS supplier_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        CASE 
            WHEN ps.ps_availqty IS NULL THEN 'Out of Stock'
            ELSE 'In Stock'
        END AS stock_status
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        (SELECT COUNT(*) FROM lineitem l WHERE l.l_orderkey = o.o_orderkey) AS line_item_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
)
SELECT 
    co.c_name,
    co.o_orderkey,
    co.o_totalprice,
    rp.rank,
    sp.p_name,
    sp.stock_status,
    sp.ps_supplycost
FROM CustomerOrders co
LEFT JOIN RankedOrders rp ON co.o_orderkey = rp.o_orderkey
JOIN SupplierParts sp ON sp.ps_partkey IN (
    SELECT DISTINCT l.l_partkey
    FROM lineitem l
    WHERE l.l_orderkey = co.o_orderkey
)
WHERE co.line_item_count > 1
  AND rp.rank < 5
ORDER BY co.o_totalprice DESC, co.c_name;
