
SELECT
    CONCAT('Supplier: ', s.s_name, ' from ', n.n_name, ' supplies ', COUNT(ps.ps_partkey), ' parts with comments: ', STRING_AGG(DISTINCT ps.ps_comment, '; ')) AS Supplier_Details,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS Total_Supply_Value,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS Avg_Sale_Price,
    COUNT(DISTINCT o.o_orderkey) AS Total_Orders
FROM
    supplier s
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    n.n_name LIKE 'A%' AND
    s.s_acctbal > 1000.00
GROUP BY
    s.s_suppkey, s.s_name, n.n_nationkey
ORDER BY
    Total_Supply_Value DESC
LIMIT 10;
