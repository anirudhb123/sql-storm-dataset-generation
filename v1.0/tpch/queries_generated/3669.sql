WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
PartSupplierDetails AS (
    SELECT
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM
        partsupp ps
    GROUP BY
        ps.ps_partkey
)
SELECT
    p.p_partkey,
    p.p_name,
    COALESCE(psd.supplier_count, 0) AS supplier_count,
    COALESCE(psd.total_supply_value, 0.00) AS total_supply_value,
    cs.total_spent,
    CASE
        WHEN cs.total_spent IS NULL THEN 'No Purchases'
        WHEN cs.total_spent > 10000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_segment,
    ns.r_name AS nation_name,
    (SELECT COUNT(DISTINCT l.l_orderkey)
     FROM lineitem l
     WHERE l.l_partkey = p.p_partkey AND l.l_discount > 0) AS order_count
FROM
    part p
LEFT JOIN
    PartSupplierDetails psd ON p.p_partkey = psd.ps_partkey
LEFT JOIN
    CustomerOrders cs ON cs.c_custkey = (
        SELECT o.o_custkey
        FROM orders o
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
        WHERE l.l_partkey = p.p_partkey
        LIMIT 1
    )
LEFT JOIN
    nation ns ON ns.n_nationkey = (
        SELECT s.s_nationkey
        FROM supplier s
        WHERE s.s_suppkey = (
            SELECT ps.ps_suppkey
            FROM partsupp ps
            WHERE ps.ps_partkey = p.p_partkey
            LIMIT 1
        )
    )
ORDER BY
    p.p_partkey;
