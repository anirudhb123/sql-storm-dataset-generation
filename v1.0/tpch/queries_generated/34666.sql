WITH RECURSIVE SupplyChain AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_acctbal,
        0 AS level
    FROM
        supplier s
    WHERE
        s.s_acctbal > (SELECT AVG(s1.s_acctbal) FROM supplier s1)
    UNION ALL
    SELECT
        ps.ps_suppkey,
        sup.s_name,
        sup.s_address,
        sup.s_nationkey,
        sup.s_acctbal,
        sc.level + 1
    FROM
        SupplyChain sc
    JOIN partsupp ps ON ps.ps_suppkey = sc.s_suppkey
    JOIN supplier sup ON sup.s_suppkey = ps.ps_suppkey
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_purchase
    FROM
        customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
),
RankedOrders AS (
    SELECT
        co.*,
        RANK() OVER (PARTITION BY co.c_custkey ORDER BY co.total_purchase DESC) AS rank
    FROM
        CustomerOrders co
),
FilteredSuppliers AS (
    SELECT
        sc.s_suppkey,
        sc.s_name,
        COALESCE(NULLIF(sc.s_address, ''), 'Unknown') AS s_address,
        sc.level
    FROM
        SupplyChain sc
    WHERE
        sc.level = (SELECT MAX(level) FROM SupplyChain)
)
SELECT
    r.r_name,
    fs.s_name AS supplier_name,
    ro.c_name AS customer_name,
    ro.total_purchase,
    r.r_comment
FROM
    RankedOrders ro
LEFT JOIN FilteredSuppliers fs ON fs.s_suppkey = ro.o_orderkey
JOIN nation n ON n.n_nationkey = ro.c_custkey
JOIN region r ON r.r_regionkey = n.n_regionkey
WHERE
    ro.rank = 1
    AND ro.total_purchase IS NOT NULL
ORDER BY
    r.r_name, ro.total_purchase DESC
LIMIT 100;
