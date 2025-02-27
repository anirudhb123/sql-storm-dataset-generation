WITH RECURSIVE SupplierHierarchy AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        0 AS level,
        CAST(s.s_name AS VARCHAR(255)) AS path
    FROM
        supplier s
    WHERE
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        sh.level + 1,
        CAST(CONCAT(sh.path, ' > ', s.s_name) AS VARCHAR(255))
    FROM
        supplier s
    JOIN
        SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE
        sh.level < 3
),
OrderSummary AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY
        o.o_orderkey
),
TopCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        c.c_acctbal IS NOT NULL
    GROUP BY
        c.c_custkey, c.c_name
    HAVING
        SUM(o.o_totalprice) > 10000
),
FinalReport AS (
    SELECT
        nh.n_name,
        COUNT(DISTINCT p.p_partkey) AS num_parts,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(s.s_acctbal) AS avg_supplier_balance
    FROM
        nation nh
    LEFT JOIN
        supplier s ON nh.n_nationkey = s.s_nationkey
    LEFT JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY
        nh.n_name
)
SELECT
    r.r_name,
    COALESCE(fr.num_parts, 0) AS total_parts,
    COALESCE(fr.total_available_quantity, 0) AS total_qty,
    COALESCE(fr.avg_supplier_balance, 0.00) AS avg_balance,
    tc.total_spent AS top_customer_spending
FROM
    region r
LEFT JOIN
    FinalReport fr ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = fr.n_nationkey)
LEFT JOIN
    TopCustomers tc ON r.r_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = tc.c_nationkey)
ORDER BY
    r.r_name;
