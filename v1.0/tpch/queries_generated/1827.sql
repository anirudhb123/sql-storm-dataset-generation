WITH RegionalSales AS (
    SELECT
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM
        lineitem l
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    WHERE
        l.l_shipdate >= DATE '2023-01-01'
        AND l.l_shipdate < DATE '2024-01-01'
    GROUP BY
        n.n_name, r.r_name
),

TopNations AS (
    SELECT
        nation_name,
        region_name,
        total_sales
    FROM
        RegionalSales
    WHERE
        sales_rank <= 3
)

SELECT
    tn.nation_name,
    tn.region_name,
    COALESCE(SUM(ps.ps_availqty), 0) AS total_available_quantity,
    ROUND(AVG(p.p_retailprice), 2) AS avg_retail_price,
    (SELECT COUNT(DISTINCT c.c_custkey)
     FROM customer c
     WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = tn.nation_name)
     AND c.c_acctbal > 5000) AS affluent_customers
FROM
    TopNations tn
LEFT JOIN
    partsupp ps ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#23')
LEFT JOIN
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY
    tn.nation_name, tn.region_name
ORDER BY
    tn.region_name, tn.nation_name;
