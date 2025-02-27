WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE
        s.s_acctbal IS NOT NULL
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM
        orders o
    JOIN
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE
        o.o_orderstatus = 'F' AND
        li.l_shipdate >= '2023-01-01'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(li.l_extendedprice * (1 - li.l_discount)) > 10000
)
SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT cust.c_custkey) AS customer_count,
    COALESCE(SUM(sup.s_acctbal), 0) AS total_supplier_acctbal,
    COALESCE(SUM(hv.total_revenue), 0) AS total_high_value_revenue
FROM 
    nation n
LEFT JOIN 
    customer cust ON n.n_nationkey = cust.c_nationkey
LEFT JOIN 
    RankedSuppliers sup ON n.n_nationkey = (SELECT n2.n_nationkey FROM supplier s2 JOIN partsupp ps ON s2.s_suppkey = ps.ps_suppkey JOIN nation n2 ON s2.s_nationkey = n2.n_nationkey WHERE ps.ps_partkey = sup.s_suppkey LIMIT 1)
LEFT JOIN 
    HighValueOrders hv ON cust.c_custkey = hv.o_orderkey
GROUP BY 
    n.n_name
ORDER BY 
    total_supplier_acctbal DESC,
    customer_count DESC;
