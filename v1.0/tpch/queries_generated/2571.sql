WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost ASC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
),
OrderLineDetail AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    p.p_name,
    ns.n_name AS supplier_nation,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
    AVG(o.total_price) AS average_order_value,
    CTE_Rank.rank
FROM 
    RankedSuppliers CTE_Rank
JOIN 
    partsupp ps ON CTE_Rank.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON s.s_suppkey = ps.ps_suppkey
JOIN 
    nation ns ON s.s_nationkey = ns.n_nationkey
LEFT JOIN 
    LineItem l ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    OrderLineDetail o ON o.o_orderkey = l.l_orderkey
WHERE 
    CTE_Rank.rank = 1 
    AND p.p_retailprice < (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size > 10)
GROUP BY 
    p.p_name, ns.n_name, CTE_Rank.rank
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    net_revenue DESC, average_order_value DESC;
