WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank,
        c.c_name,
        c.c_acctbal,
        r.r_name
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartSales AS (
    SELECT 
        ps.ps_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS sales_count
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
    GROUP BY 
        ps.ps_partkey
),
SupplierRanking AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        RANK() OVER (ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
TopPart AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.total_sales,
        ps.sales_count
    FROM 
        part p
    JOIN 
        PartSales ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.total_sales > (
            SELECT 
                AVG(total_sales) 
            FROM 
                PartSales
        )
)
SELECT 
    r.r_name AS region,
    top.p_name AS part_name,
    top.total_sales,
    s.s_name AS supplier_name,
    s.s_acctbal,
    COUNT(DISTINCT ro.o_orderkey) AS order_count
FROM 
    SupplierRanking s
LEFT JOIN 
    TopPart top ON s.s_acctbal > (SELECT MAX(c.c_acctbal) FROM customer c WHERE c.c_mktsegment = 'BUILDING')
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey IN (
        SELECT o.o_orderkey FROM orders o 
        WHERE o.o_orderstatus = 'O'
    )
WHERE 
    (ROLES IN ('Admin', 'User') OR ro.o_orderkey IS NULL)
    AND top.total_sales IS NOT NULL
GROUP BY 
    r.r_name, top.p_name, s.s_name, s.s_acctbal
HAVING 
    SUM(CASE WHEN ro.order_rank = 1 THEN 1 ELSE 0 END) > 0
ORDER BY 
    top.total_sales DESC, s.s_acctbal ASC;
