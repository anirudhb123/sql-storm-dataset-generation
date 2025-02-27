WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' 
      AND o.o_orderdate < DATE '1998-01-01'
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        COUNT(DISTINCT p.p_partkey) AS unique_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    r.r_name,
    COALESCE(o.o_orderkey, 0) AS order_key,
    COALESCE(cs.total_spent, 0) AS customer_total_spent,
    ss.total_supplycost,
    ss.unique_parts,
    COUNT(DISTINCT l.l_orderkey) AS lineitem_count,
    AVG(l.l_extendedprice - (l.l_extendedprice * l.l_discount)) AS avg_price_after_discount
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN CustomerOrders cs ON cs.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey ORDER BY c.c_acctbal DESC LIMIT 1)
LEFT JOIN lineitem l ON l.l_suppkey = s.s_suppkey
LEFT JOIN RankedOrders o ON o.o_orderkey = l.l_orderkey
WHERE ss.total_supplycost > 10000
GROUP BY r.r_name, o.o_orderkey, cs.total_spent, ss.total_supplycost, ss.unique_parts
HAVING COUNT(l.l_orderkey) > 5
ORDER BY r.r_name, customer_total_spent DESC;