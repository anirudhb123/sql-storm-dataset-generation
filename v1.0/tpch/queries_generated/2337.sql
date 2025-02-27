WITH RankedSales AS (
    SELECT
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM
        part p
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY
        p.p_partkey, p.p_name
),
TopSales AS (
    SELECT * FROM RankedSales WHERE rank <= 10
),
SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS supply_count
    FROM
        supplier s
    LEFT JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, s.s_nationkey
),
NationSummary AS (
    SELECT
        n.n_name,
        SUM(CASE WHEN c.c_acctbal IS NOT NULL THEN c.c_acctbal ELSE 0 END) AS total_acctbal,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM
        nation n
    JOIN
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY
        n.n_name
)
SELECT
    ts.p_name,
    ts.total_sales,
    sd.s_name AS supplier_name,
    ns.n_name AS nation_name,
    ns.total_acctbal,
    ns.customer_count
FROM
    TopSales ts
LEFT JOIN
    SupplierDetails sd ON ts.p_partkey = sd.s_nationkey
LEFT JOIN
    NationSummary ns ON sd.s_nationkey = ns.n_name
WHERE
    ts.total_sales > (SELECT AVG(total_sales) FROM TopSales) 
    AND ns.customer_count > 50
ORDER BY
    ts.total_sales DESC, ns.total_acctbal ASC;
