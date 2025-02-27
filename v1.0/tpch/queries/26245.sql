SELECT
    n.n_name AS Nation,
    COUNT(DISTINCT c.c_custkey) AS Total_Customers,
    SUM(o.o_totalprice) AS Total_Revenue,
    SUM(l.l_quantity) AS Total_Quantity,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_size, ' ', p.p_container, ')'), ', ') AS Part_Details,
    MAX(l.l_shipdate) AS Latest_Shipdate
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
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
WHERE
    p.p_brand LIKE 'Brand#%'
    AND o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY
    n.n_name
ORDER BY
    Total_Revenue DESC;