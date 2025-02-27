WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM
        supplier s
),
ActiveCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COALESCE(c.c_mktsegment, 'Unknown') AS segment
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_acctbal IS NOT NULL)
),
Sales AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(r.region_name, 'Unknown') AS region_name,
    s.s_name AS supplier_name,
    ac.c_name AS customer_name,
    CASE 
        WHEN ls.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sale_status,
    RANK() OVER (PARTITION BY n.n_regionkey ORDER BY p.p_retailprice DESC) AS price_rank
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    ActiveCustomers ac ON ac.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = (SELECT MIN(o2.o_orderkey) FROM orders o2 WHERE o2.o_custkey IN (SELECT c.c_custkey FROM ActiveCustomers c)))
LEFT JOIN 
    Sales ls ON ls.o_orderkey = (SELECT MAX(o.o_orderkey) FROM orders o WHERE o.o_orderkey < 50000)
WHERE 
    p.p_container LIKE '%BOX%' 
    AND (p.p_retailprice < 100 OR p.p_brand IS NULL)
ORDER BY 
    price_rank, p.p_name;
