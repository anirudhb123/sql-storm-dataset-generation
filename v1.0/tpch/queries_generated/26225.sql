SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    SUM(l.l_extendedprice * l.l_discount) AS total_discount,
    RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(l.l_extendedprice) DESC) AS price_rank
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_custkey IN (
        SELECT o.o_custkey
        FROM orders o
        WHERE o.o_orderdate >= '2022-01-01' AND o.o_orderdate < '2023-01-01'
    )
GROUP BY 
    p.p_name, p.p_type
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 2 AND 
    SUM(l.l_quantity) > 1000
ORDER BY 
    price_rank, total_quantity DESC;
