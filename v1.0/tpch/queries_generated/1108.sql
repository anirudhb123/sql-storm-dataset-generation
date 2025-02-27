WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM
        orders o
    WHERE
        o.o_orderdate >= DATE '2023-01-01'
),
SupplierParts AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, ps.ps_partkey
),
CustomerTotal AS (
    SELECT
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey
),
PartDetails AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COUNT(l.l_orderkey) AS order_count
    FROM
        part p
    LEFT JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY
        p.p_partkey, p.p_name, p.p_retailprice
)
SELECT
    coalesce(c.c_name, 'Unknown Customer') AS customer_name,
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    o.o_totalprice AS order_total,
    r.total_available_qty AS qty_available,
    p.p_retailprice AS retail_price,
    c.total_spent AS customer_spending,
    CASE 
        WHEN o.o_orderkey IS NOT NULL THEN 'Order Present'
        ELSE 'No Order'
    END AS order_status,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS recent_order_rank
FROM
    PartDetails p
LEFT JOIN
    SupplierParts r ON p.p_partkey = r.ps_partkey
LEFT JOIN
    RankedOrders o ON o.o_orderkey = (
        SELECT MAX(o2.o_orderkey)
        FROM orders o2
        WHERE o2.o_totalprice < p.p_retailprice
    )
LEFT JOIN
    customer c ON c.c_custkey = (
        SELECT c2.c_custkey
        FROM CustomerTotal c2
        WHERE c2.total_spent > 1000
        LIMIT 1
    )
LEFT JOIN
    nation n ON n.n_nationkey = (CASE WHEN c.c_nationkey IS NULL THEN 0 ELSE c.c_nationkey END)
WHERE
    p.order_count > 0
ORDER BY
    c.c_custkey, p.p_name;
