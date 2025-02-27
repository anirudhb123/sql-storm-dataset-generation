WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1995-01-01' 
    AND o.o_orderstatus IN ('O', 'F')
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_supplycost,
        p.p_name,
        p.p_brand,
        p.p_container,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY ps.ps_supplycost DESC) AS supply_rank
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 100.00
),
CustomerNation AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        n.n_comment,
        COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, n.n_name, n.n_comment
    HAVING COUNT(o.o_orderkey) > 5
)
SELECT 
    cn.nation_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(s.s_acctbal) AS avg_supplier_balance 
FROM lineitem l
JOIN RankedOrders ro ON l.l_orderkey = ro.o_orderkey
JOIN SupplierPartDetails spd ON l.l_partkey = spd.p_partkey
JOIN partsupp ps ON spd.p_name = (SELECT p2.p_name FROM part p2 WHERE p2.p_partkey = l.l_partkey)
LEFT OUTER JOIN customer c ON c.c_custkey = ro.o_custkey
JOIN nation cn ON c.c_nationkey = cn.n_nationkey
WHERE l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1997-01-01'
AND l.l_returnflag = 'N'
AND spd.supply_rank < 5
GROUP BY cn.nation_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) IS NOT NULL
ORDER BY total_revenue DESC
LIMIT 10;
