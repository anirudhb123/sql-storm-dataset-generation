
WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rnk
    FROM
        part p
),
SupplierParts AS (
    SELECT
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(*) AS supply_count
    FROM
        partsupp ps
    GROUP BY
        ps.ps_partkey, ps.ps_suppkey
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        c.c_acctbal IS NOT NULL
    GROUP BY
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        COALESCE(SUM(sp.total_avail_qty), 0) AS total_avail_qty
    FROM
        supplier s
    LEFT JOIN
        SupplierParts sp ON s.s_suppkey = sp.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
    HAVING
        SUM(sp.total_avail_qty) > 100
),
OrderYears AS (
    SELECT
        EXTRACT(YEAR FROM o.o_orderdate) AS order_year,
        AVG(o.o_totalprice) AS average_price
    FROM
        orders o
    GROUP BY
        EXTRACT(YEAR FROM o.o_orderdate)
),
BizarreJoin AS (
    SELECT
        np.n_name AS nation,
        p.p_name AS part,
        CASE 
            WHEN SUM(l.l_quantity) IS NULL THEN 'No Quantity'
            ELSE 'Has Quantity'
        END AS quantity_status
    FROM
        nation np
    LEFT JOIN
        supplier s ON np.n_nationkey = s.s_nationkey
    LEFT JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY
        np.n_name,
        p.p_name
)
SELECT
    c.c_name AS customer_name,
    c.order_count,
    c.total_spent,
    tp.total_avail_qty,
    p.p_name,
    p.p_retailprice,
    o.order_year,
    o.average_price,
    bz.quantity_status
FROM
    CustomerOrders c
JOIN
    TopSuppliers tp ON c.order_count > 0
JOIN
    RankedParts p ON EXISTS (
        SELECT
            1
        FROM
            SupplierParts sp
        WHERE
            sp.ps_partkey = p.p_partkey AND
            sp.total_avail_qty > 50
    )
JOIN
    OrderYears o ON o.average_price < (SELECT AVG(o2.o_totalprice) FROM orders o2)
LEFT JOIN
    BizarreJoin bz ON bz.part = p.p_name
WHERE
    c.total_spent BETWEEN 100 AND 10000
ORDER BY
    c.order_count DESC, tp.total_avail_qty ASC;
