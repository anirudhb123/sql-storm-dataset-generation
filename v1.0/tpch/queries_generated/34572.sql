WITH RECURSIVE OrderHierarchy AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_custkey,
        0 AS level
    FROM
        orders o
    WHERE
        o.o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_custkey,
        oh.level + 1
    FROM
        orders o
    INNER JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE
        o.o_orderdate > oh.o_orderdate
),
PartSupplier AS (
    SELECT
        p.p_partkey,
        avg(ps.ps_supplycost) AS avg_supplycost,
        sum(ps.ps_availqty) AS total_availqty
    FROM
        part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY
        p.p_partkey
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
CustomerOrderSummary AS (
    SELECT
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey
)
SELECT
    ch.o_orderkey,
    ch.o_orderdate,
    co.c_custkey,
    CASE WHEN ch.o_orderkey IS NOT NULL THEN 'Active' ELSE 'Inactive' END AS order_status,
    pi.avg_supplycost,
    pi.total_availqty,
    CASE 
        WHEN pi.total_availqty IS NULL OR pi.total_availqty = 0 THEN 'No Supply'
        ELSE 'Available'
    END AS supply_status,
    si.s_name AS top_supplier
FROM
    OrderHierarchy ch
LEFT JOIN CustomerOrderSummary co ON ch.o_custkey = co.c_custkey
LEFT JOIN PartSupplier pi ON ch.o_orderkey = (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_orderkey = ch.o_orderkey
    LIMIT 1
)
LEFT JOIN SupplierInfo si ON si.rn = 1
WHERE
    ch.level = (
        SELECT MAX(level) FROM OrderHierarchy
    )
ORDER BY
    ch.o_orderdate DESC, co.total_spent DESC;
