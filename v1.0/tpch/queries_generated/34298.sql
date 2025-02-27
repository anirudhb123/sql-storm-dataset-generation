WITH RECURSIVE SalesCTE AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_custkey
),
SupplierInfo AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        (ps.ps_availqty * ps.ps_supplycost) AS supply_value
    FROM
        supplier s
    INNER JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE
        ps.ps_availqty > (SELECT AVG(ps_availqty) FROM partsupp) 
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_size,
    p.p_retailprice,
    CASE 
        WHEN p.p_container IS NULL THEN 'No Container Info'
        ELSE p.p_container
    END AS container_info,
    COALESCE((SELECT COUNT(*) FROM lineitem l WHERE l.l_partkey = p.p_partkey AND l.l_returnflag = 'R'), 0) AS returned_items,
    COALESCE(si.total_sales, 0) AS supplier_total_sales,
    CASE
        WHEN s.s_suppkey IS NOT NULL THEN 'Supplied'
        ELSE 'Not Supplied'
    END AS supply_status
FROM 
    part p
LEFT JOIN 
    SupplierInfo si ON p.p_partkey = si.ps_partkey
LEFT JOIN 
    (SELECT DISTINCT o.o_orderkey, c.c_nationkey
     FROM orders o
     JOIN customer c ON o.o_custkey = c.c_custkey) AS o_cust_info ON o_cust_info.o_orderkey = ANY (SELECT o_orderkey FROM orders)
LEFT JOIN 
    supplier s ON si.s_suppkey = s.s_suppkey
WHERE 
    p.p_retailprice > (SELECT AVG(p_retailprice) FROM part WHERE p_size > 10)
ORDER BY 
    p.p_partkey
LIMIT 100;
