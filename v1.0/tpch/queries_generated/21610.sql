WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(DISTINCT l.l_linenumber) AS item_count,
        DENSE_RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS value_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey
),
SupplierOrderCount AS (
    SELECT 
        ps.ps_suppkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        ps.ps_suppkey
),
NationsWithComments AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        CASE 
            WHEN n.n_comment IS NULL THEN 'No Comment'
            ELSE n.n_comment 
        END as comment
    FROM
        nation n
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    od.total_value,
    od.item_count,
    soc.order_count,
    CASE WHEN sc.rn <= 3 THEN 'Top Supplier' ELSE 'Other Supplier' END AS supplier_rank,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY od.total_value DESC) AS regional_order_rank
FROM 
    region r
JOIN 
    nationsWithComments n ON n.n_nationkey = r.r_regionkey
JOIN 
    RankedSuppliers s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_availqty > 0)
LEFT JOIN 
    OrderDetails od ON od.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey))
LEFT JOIN 
    SupplierOrderCount soc ON soc.ps_suppkey = s.s_suppkey
WHERE 
    od.total_value IS NOT NULL
ORDER BY 
    region, od.total_value DESC
LIMIT 100;
