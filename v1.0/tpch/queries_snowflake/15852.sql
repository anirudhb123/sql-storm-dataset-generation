
SELECT 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM 
    lineitem
WHERE 
    l_shipdate >= DATE '1996-01-01' AND l_shipdate < DATEADD(YEAR, 1, DATE '1996-01-01');
