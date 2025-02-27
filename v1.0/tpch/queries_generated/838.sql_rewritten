WITH SupplierSales AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        SUM(l.l_extendedprice * (1 - l.l_discount) * 0.1) AS total_commission
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY
        s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_orderstatus = 'O'
    GROUP BY
        c.c_custkey, c.c_name
    HAVING
        SUM(o.o_totalprice) > 10000
),
SalesByRegion AS (
    SELECT
        n.n_nationkey,
        r.r_regionkey,
        SUM(ss.total_sales) AS region_sales
    FROM
        nation n
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN
        SupplierSales ss ON ss.s_suppkey IN (
            SELECT ps.ps_suppkey
            FROM partsupp ps
            WHERE ps.ps_partkey IN (
                SELECT p.p_partkey
                FROM part p
                WHERE p.p_mfgr = 'Manufacturer#1'
            )
        )
    GROUP BY
        n.n_nationkey, r.r_regionkey
),
RankedSales AS (
    SELECT
        r.r_regionkey,
        SUM(sb.region_sales) AS total_region_sales,
        RANK() OVER (ORDER BY SUM(sb.region_sales) DESC) AS region_rank
    FROM
        SalesByRegion sb
    JOIN
        region r ON sb.r_regionkey = r.r_regionkey
    GROUP BY
        r.r_regionkey
),
TopSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        COALESCE(HVC.total_spent, 0) AS high_value_sales,
        ss.total_sales AS supplier_sales
    FROM
        supplier s
    LEFT JOIN
        HighValueCustomers HVC ON s.s_suppkey = HVC.c_custkey
    JOIN
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
)
SELECT
    r.r_name,
    t.s_name,
    t.high_value_sales,
    t.supplier_sales,
    CASE 
        WHEN t.high_value_sales > t.supplier_sales THEN 'High Value'
        ELSE 'Regular'
    END AS supplier_type
FROM
    TopSuppliers t
JOIN
    region r ON r.r_regionkey = (
        SELECT n.n_regionkey
        FROM nation n
        WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = t.s_suppkey)
    )
WHERE
    t.supplier_sales IS NOT NULL
ORDER BY
    r.r_name, t.supplier_sales DESC;