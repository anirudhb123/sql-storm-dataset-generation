WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
), 
TotalSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate <= CURRENT_DATE
    GROUP BY 
        l.l_partkey
),
FrequentBuyers AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_custkey
    HAVING 
        COUNT(o.o_orderkey) > 5
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(ts.total_revenue, 0) AS total_revenue,
    rs.s_name AS top_supplier,
    fb.order_count
FROM 
    part p 
LEFT JOIN 
    TotalSales ts ON p.p_partkey = ts.l_partkey
LEFT JOIN 
    RankedSuppliers rs ON rs.rank = 1 AND rs.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA') 
LEFT JOIN 
    FrequentBuyers fb ON fb.o_custkey = (SELECT c.c_custkey 
                                          FROM customer c 
                                          WHERE c.c_nationkey = (SELECT n.n_nationkey 
                                                                 FROM nation n 
                                                                 WHERE n.n_name = 'USA') 
                                          LIMIT 1)
WHERE 
    p.p_size BETWEEN 10 AND 20 AND 
    p.p_retailprice IS NOT NULL
ORDER BY 
    total_revenue DESC, 
    p.p_name ASC
LIMIT 100
OFFSET (SELECT COUNT(*) FROM part) / 2;
