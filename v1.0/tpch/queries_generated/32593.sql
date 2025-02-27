WITH RECURSIVE SupplyChain AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty > 0
),
AggregatedOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.custkey
),
QualifiedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.r_name,
    n.n_name,
    SUM(sc.ps_availqty) AS total_available_quantity,
    COALESCE(SUM(qp.total_revenue), 0) AS total_part_revenue,
    AVG(ao.total_spent) AS avg_customer_spending
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplyChain sc ON n.n_nationkey = (SELECT s_nationkey FROM supplier s WHERE s.s_suppkey = sc.s_suppkey)
LEFT JOIN 
    AggregatedOrders ao ON n.n_nationkey = (SELECT c_nationkey FROM customer c WHERE c.c_custkey = ao.c_custkey)
LEFT JOIN 
    QualifiedParts qp ON sc.s_suppkey = (SELECT ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = qp.p_partkey)
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
