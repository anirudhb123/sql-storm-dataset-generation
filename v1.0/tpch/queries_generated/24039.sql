WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        DENSE_RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(ps.ps_partkey) AS part_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
    HAVING COUNT(ps.ps_partkey) > 0
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        c.c_name,
        LAG(o.o_totalprice) OVER (ORDER BY o.o_orderdate) AS previous_order_price
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'F' AND o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
PartSupplyInfo AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(ps.ps_suppkey) AS total_suppliers
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
    HAVING total_suppliers > 5
)
SELECT 
    np.n_name,
    rp.price_rank,
    ts.s_name,
    ts.s_acctbal,
    hvo.o_orderkey,
    hvo.o_totalprice,
    CASE 
        WHEN hvo.previous_order_price IS NULL THEN 'First Order'
        WHEN hvo.o_totalprice > hvo.previous_order_price THEN 'Price Increased'
        ELSE 'Price Decreased'
    END AS price_trend,
    psi.total_supply_cost,
    psi.total_suppliers
FROM RankedParts rp
JOIN region r ON r.r_regionkey IN (SELECT DISTINCT n.n_regionkey FROM nation n WHERE n.n_nationkey IN (
    SELECT DISTINCT s_nationkey FROM supplier
))
LEFT JOIN TopSuppliers ts ON ts.part_count = (SELECT MAX(part_count) FROM TopSuppliers)
JOIN HighValueOrders hvo ON hvo.o_orderkey = (SELECT MIN(o_orderkey) FROM HighValueOrders)
JOIN PartSupplyInfo psi ON psi.p_partkey = rp.p_partkey
JOIN nation np ON np.n_nationkey = (SELECT MAX(n_nationkey) FROM nation);
