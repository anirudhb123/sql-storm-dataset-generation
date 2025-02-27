WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_size, p_retailprice, 1 AS level
    FROM part
    WHERE p_size > 10
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_size, p.p_retailprice * 0.9, ph.level + 1
    FROM part p
    JOIN PartHierarchy ph ON ph.p_partkey = p.p_partkey
    WHERE ph.level < 3
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supplycost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > 1000
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_mktsegment = 'BUILDING' OR c.c_mktsegment IS NULL
    GROUP BY c.c_custkey, c.c_name
),
DateFilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_price,
        l.l_returnflag,
        l.l_linestatus
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '1995-01-01' AND '1996-12-31'
    GROUP BY l.l_orderkey, l.l_returnflag, l.l_linestatus
)
SELECT 
    ph.p_name,
    si.s_name,
    co.c_name,
    dfl.net_price,
    COUNT(DISTINCT dfl.l_orderkey) AS order_count
FROM PartHierarchy ph
JOIN SupplierInfo si ON si.total_supplycost > 5000
JOIN CustomerOrders co ON co.order_count > 10
LEFT JOIN DateFilteredLineItems dfl ON dfl.net_price > 100
WHERE dfl.l_returnflag = 'R' OR dfl.l_linestatus = 'O'
GROUP BY ph.p_name, si.s_name, co.c_name, dfl.net_price
HAVING AVG(dfl.net_price) > 200
ORDER BY ph.p_retailprice DESC, si.part_count ASC;
