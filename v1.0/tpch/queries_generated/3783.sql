WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rank
    FROM
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_totalprice
    HAVING 
        SUM(li.l_extendedprice * (1 - li.l_discount)) > 5000
),
NationCounts AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_name
    HAVING 
        COUNT(DISTINCT c.c_custkey) > 10
)
SELECT 
    ns.n_name,
    ns.customer_count,
    rs.s_name,
    rs.s_acctbal,
    ho.o_orderkey,
    ho.total_value
FROM 
    NationCounts ns
LEFT JOIN 
    RankedSuppliers rs ON ns.customer_count > 10 
LEFT JOIN 
    HighValueOrders ho ON ho.o_orderkey IN (
        SELECT 
            o.o_orderkey 
        FROM 
            orders o
        JOIN 
            lineitem li ON o.o_orderkey = li.l_orderkey
        WHERE 
            li.l_quantity > ALL (
                SELECT AVG(li2.l_quantity)
                FROM lineitem li2
            )
    )
WHERE 
    rs.rank = 1
ORDER BY 
    ns.n_name, ho.total_value DESC

