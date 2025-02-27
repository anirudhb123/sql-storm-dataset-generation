WITH SupplierPartInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ps.ps_availqty,
        ps.ps_supplycost,
        (ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
OrderSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_mktsegment = 'BUILDING'
    GROUP BY c.c_custkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(total_supply_value) AS supplier_value
    FROM SupplierPartInfo
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(total_supply_value) > 100000
),
RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS price_rank,
        c.c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
)
SELECT 
    h.s_name,
    h.supplying_count,
    r.o_orderkey,
    r.o_totalprice,
    r.price_rank,
    o.order_count,
    o.total_spent
FROM HighValueSuppliers h
JOIN (
    SELECT s_suppkey, COUNT(p_partkey) AS supplying_count
    FROM SupplierPartInfo
    GROUP BY s_suppkey
) AS supplier_count ON h.s_suppkey = supplier_count.s_suppkey
LEFT JOIN RankedOrders r ON h.s_suppkey = r.o_orderkey
JOIN OrderSummary o ON r.c_nationkey = o.c_custkey
WHERE o.total_spent IS NOT NULL
ORDER BY h.s_name, r.price_rank;
