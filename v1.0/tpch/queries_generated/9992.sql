WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
TopSuppliers AS (
    SELECT
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal
    FROM
        RankedSuppliers rs
    WHERE
        rs.rank <= 5
),
PartSupplierMetrics AS (
    SELECT
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM
        partsupp ps
    GROUP BY
        ps.ps_partkey
),
OrderSummary AS (
    SELECT
        o.o_orderkey,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS lineitem_count
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_totalprice
)
SELECT
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_type,
    p.p_retailprice,
    o.lineitem_count,
    o.o_totalprice,
    ps.supplier_count,
    ps.total_supply_value,
    r.r_name
FROM
    part p
LEFT JOIN
    PartSupplierMetrics ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN
    OrderSummary o ON o.o_orderkey IN (
        SELECT o_orderkey FROM orders WHERE o_orderdate >= DATE '2023-01-01' AND o_orderdate < DATE '2024-01-01'
    )
JOIN
    region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n JOIN supplier s ON n.n_nationkey = s.s_nationkey WHERE s.s_suppkey IN (SELECT s_suppkey FROM TopSuppliers))
WHERE
    p.p_retailprice > 50.00
ORDER BY
    p.p_partkey, ps.supplier_count DESC, o.o_totalprice DESC;
