WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        COUNT(s.s_suppkey) AS supplier_count
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartNations AS (
    SELECT 
        p.p_partkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS number_of_suppliers
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY p.p_partkey, n.n_name
)
SELECT 
    c.c_custkey,
    c.c_name,
    o.o_orderkey,
    o.o_totalprice,
    COALESCE(spd.total_available, 0) AS total_available_qty,
    COALESCE(spd.avg_supplycost, 0) AS average_supply_cost,
    cn.number_of_suppliers,
    CASE WHEN o.o_totalprice IS NULL THEN 'No orders' ELSE 'Has orders' END AS order_status,
    CONCAT('Customer ', c.c_name, ' with orders totaling: $', COALESCE(o.o_totalprice, 0)) AS order_info
FROM customer c
LEFT JOIN RankedOrders o ON c.c_custkey = o.o_custkey AND o.rn = 1
LEFT JOIN SupplierPartDetails spd ON EXISTS (
    SELECT 1 FROM partsupp ps WHERE spd.ps_partkey = ps.ps_partkey AND ps.ps_availqty > 0
)
LEFT JOIN PartNations cn ON cn.p_partkey = spd.ps_partkey
WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > (
    SELECT AVG(c_acctbal) FROM customer 
    WHERE c_nationkey IN (SELECT n_nationkey FROM nation WHERE n_comment LIKE '%important%')
)
ORDER BY c.c_custkey, o.o_orderdate DESC NULLS LAST;
