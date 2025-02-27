SELECT
    p.p_name AS Part_Name,
    s.s_name AS Supplier_Name,
    c.c_name AS Customer_Name,
    COUNT(o.o_orderkey) AS Total_Orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Revenue,
    AVG(l.l_quantity) AS Average_Quantity,
    MAX(l.l_shipdate) AS Last_Ship_Date,
    MIN(l.l_shipdate) AS First_Ship_Date,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS Combined_Comments
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
WHERE
    p.p_size >= 10
    AND s.s_acctbal > 1000.00
    AND c.c_mktsegment = 'BUILDING'
GROUP BY
    p.p_name, s.s_name, c.c_name
HAVING
    COUNT(o.o_orderkey) > 5
ORDER BY
    Total_Revenue DESC;
