WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate BETWEEN DATE '2022-01-01' AND CURRENT_DATE
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        COALESCE((
            SELECT SUM(l.l_quantity * (l.l_extendedprice - l.l_extendedprice * l.l_discount)) 
            FROM lineitem l 
            WHERE l.l_orderkey = ro.o_orderkey
        ), 0) AS revenue
    FROM RankedOrders ro
    WHERE ro.rn <= 10
),
PartSuppliers AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_supplycost) > (
        SELECT AVG(ps_supplycost) FROM partsupp
    )
),
SupplierNations AS (
    SELECT 
        n.n_name,
        SUM(s.s_acctbal) AS total_acctbal
    FROM supplier s
    INNER JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'A%')
    GROUP BY n.n_name
    HAVING SUM(s.s_acctbal) IS NOT NULL
    ORDER BY total_acctbal DESC
    LIMIT 3
)
SELECT 
    po.o_orderkey,
    po.o_orderdate,
    po.o_totalprice,
    ps.p_partkey,
    ps.total_supply_cost,
    ns.n_name,
    ns.total_acctbal
FROM TopOrders po
LEFT JOIN PartSuppliers ps ON po.o_orderkey = (
    SELECT COUNT(*) FROM lineitem l WHERE l.l_orderkey = po.o_orderkey
)
LEFT JOIN SupplierNations ns ON ns.total_acctbal > (SELECT AVG(total_acctbal) FROM SupplierNations)
WHERE po.o_totalprice > (SELECT AVG(o_totalprice) FROM RankedOrders) 
AND (ns.n_name IS NOT NULL OR ns.n_name IS NULL)
ORDER BY po.o_orderdate DESC, po.o_totalprice ASC;
