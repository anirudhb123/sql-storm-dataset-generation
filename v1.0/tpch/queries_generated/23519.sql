WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
)

SELECT 
    n.n_name AS nation_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    COALESCE(MAX(l.l_tax), 0) AS max_tax_value,
    STRING_AGG(DISTINCT p.p_name, ', ') AS product_list
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT OUTER JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31' 
    AND l.l_returnflag = 'N'
    AND (r.r_name IS NULL OR r.r_name LIKE '%North%')
    AND c.c_acctbal > 1000
GROUP BY 
    n.n_name
HAVING 
    total_revenue > (SELECT AVG(total_revenue) FROM (
        SELECT 
            SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
        FROM 
            lineitem l
        JOIN 
            orders o ON l.l_orderkey = o.o_orderkey
        GROUP BY 
            o.o_orderkey
    ) AS subquery) 
    AND COUNT(DISTINCT p.p_partkey) BETWEEN 1 AND 10
ORDER BY 
    total_revenue DESC
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY;
