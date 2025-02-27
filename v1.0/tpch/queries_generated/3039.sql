WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
),
CustomerTotalSpent AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(COALESCE(ps.ps_availqty, 0)) AS total_available_quantity,
    AVG(CASE 
        WHEN o.o_orderstatus = 'F' THEN o.o_totalprice 
        ELSE NULL 
    END) AS average_filled_order_price,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    RankedOrders ro ON l.l_orderkey = ro.o_orderkey
LEFT JOIN 
    CustomerTotalSpent cts ON cts.c_custkey = ro.o_custkey
INNER JOIN 
    part p ON p.p_partkey = l.l_partkey
WHERE 
    s.s_acctbal > (
        SELECT 
            AVG(s_acctbal) 
        FROM 
            supplier 
        WHERE 
            n_nationkey = s.s_nationkey
    )
AND 
    o_orderdate >= DATEADD(MONTH, -6, GETDATE())
GROUP BY 
    n.n_name
HAVING 
    COUNT(p.p_partkey) > 10
ORDER BY 
    total_available_quantity DESC;
