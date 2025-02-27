WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
), 
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N' 
        AND l.l_shipdate < CURRENT_DATE 
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderstatus, o.o_orderdate
), 
CustomerStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    n.n_name,
    COALESCE(count(DISTINCT ps.ps_partkey), 0) AS part_count,
    SUM(CASE WHEN hs.o_orderkey IS NOT NULL THEN hs.total_line_value ELSE 0 END) AS high_value_total,
    MAX(CASE WHEN rs.rnk = 1 THEN rs.s_acctbal END) AS max_account_balance,
    STRING_AGG(DISTINCT CONCAT(c.c_name, ': ', cs.order_count), ', ') AS customer_order_counts 
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    HighValueOrders hs ON hs.o_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_orderstatus = 'F' 
    )
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
LEFT JOIN 
    CustomerStats cs ON cs.c_custkey IN (
        SELECT o.o_custkey 
        FROM orders o 
        WHERE o.o_orderkey = hs.o_orderkey
    )
GROUP BY 
    n.n_name
HAVING 
    AVG(CASE WHEN rs.rnk IS NOT NULL THEN rs.s_acctbal ELSE NULL END) > 
    (SELECT AVG(s1.s_acctbal)
     FROM supplier s1 
     WHERE s1.s_acctbal IS NOT NULL)
ORDER BY 
    part_count DESC, 
    high_value_total ASC NULLS LAST;
