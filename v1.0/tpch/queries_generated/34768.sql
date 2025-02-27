WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        1 AS order_level
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        oh.order_level + 1
    FROM 
        orders o
    JOIN 
        OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE 
        o.o_orderdate < CURRENT_DATE
), RegionSpend AS (
    SELECT 
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spend
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        r.r_name
), CustomerRank AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        DENSE_RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_mktsegment
)
SELECT 
    r.r_name,
    rs.total_spend,
    cr.c_name,
    cr.customer_rank,
    oh.o_orderkey,
    oh.o_orderdate,
    oh.o_totalprice
FROM 
    RegionSpend rs
FULL OUTER JOIN 
    CustomerRank cr ON rs.r_name IS NOT NULL
LEFT JOIN 
    OrderHierarchy oh ON cr.c_custkey IS NOT NULL OR oh.o_orderdate < CURRENT_DATE
WHERE 
    (rs.total_spend IS NOT NULL AND rs.total_spend > 1000.00) 
    OR (cr.customer_rank <= 5 AND cr.customer_rank IS NOT NULL)
ORDER BY 
    rs.total_spend DESC, 
    cr.customer_rank, 
    oh.o_orderdate DESC;
