WITH RECURSIVE RegionalSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) as sales_rank
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
TopRegions AS (
    SELECT 
        r.r_name,
        rs.total_sales
    FROM 
        region r
    LEFT JOIN 
        RegionalSales rs ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = rs.n_nationkey)
    WHERE 
        rs.sales_rank <= 5
)
SELECT 
    r.r_name,
    COALESCE(SUM(tr.total_sales), 0) AS total_sales
FROM 
    region r
LEFT JOIN 
    TopRegions tr ON r.r_name = tr.r_name
GROUP BY 
    r.r_name
ORDER BY 
    total_sales DESC;

WITH CheckConstraints AS (
    SELECT 
        DISTINCT c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    INNER JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_orderdate >= DATE '2023-01-01' 
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    c.c_name,
    CASE 
        WHEN cs.total_spent IS NOT NULL THEN cs.total_spent
        ELSE 0
    END AS amount_spent 
FROM 
    customer c 
LEFT JOIN 
    CheckConstraints cs ON c.c_custkey = cs.c_custkey
WHERE 
    c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
ORDER BY 
    amount_spent DESC
LIMIT 10;
