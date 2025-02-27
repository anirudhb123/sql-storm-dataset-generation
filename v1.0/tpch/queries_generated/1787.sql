WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank_by_price
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderstatus = 'O'
),
SupplierParts AS (
    SELECT
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM
        partsupp ps
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY
        ps.ps_partkey, ps.ps_suppkey
),
TopProducts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        COALESCE(sp.total_availqty, 0) AS total_availqty,
        COALESCE(sp.avg_supplycost, 0) AS avg_supplycost
    FROM
        part p
    LEFT JOIN
        SupplierParts sp ON p.p_partkey = sp.ps_partkey
    WHERE
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
)
SELECT
    r.r_name,
    tp.p_name,
    tp.p_brand,
    tp.total_availqty,
    tp.avg_supplycost,
    COUNT(RO.o_orderkey) AS total_orders,
    SUM(RO.o_totalprice) AS total_revenue
FROM
    TopProducts tp
JOIN
    RankedOrders RO ON tp.p_partkey = (
        SELECT l.l_partkey
        FROM lineitem l
        WHERE l.l_orderkey = RO.o_orderkey
        LIMIT 1
    )
JOIN
    nation n ON (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = RO.o_custkey) = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY
    r.r_name, tp.p_name, tp.p_brand, tp.total_availqty, tp.avg_supplycost
HAVING
    COUNT(RO.o_orderkey) > 0 AND
    SUM(RO.o_totalprice) > 10000
ORDER BY
    r.r_name, total_revenue DESC;
