WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
TotalBeerCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_cost
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    WHERE 
        l.l_returnflag = 'R' AND 
        l.l_shipdate >= DATE '2022-01-01' AND 
        l.l_shipdate < DATE '2023-01-01'
    GROUP BY 
        ps.ps_partkey
),
AvgSalesPerCustomer AS (
    SELECT 
        c.c_custkey,
        AVG(o.o_totalprice) AS avg_sales
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    n.n_name,
    p.p_name,
    COALESCE(SUM(l.l_extendedprice), 0) AS total_lineitem_value,
    CASE 
        WHEN r.r_name IS NULL THEN 'UNKNOWN REGION'
        ELSE r.r_name
    END AS region_name,
    (SELECT COUNT(DISTINCT o.o_orderkey) 
     FROM orders o 
     WHERE o.o_orderstatus = 'F' AND o.o_totalprice > 1000) AS high_value_finished_orders,
    (SELECT AVG(acctbal) FROM supplier WHERE s_nationkey = n.n_nationkey) AS avg_supplier_acctbal,
    (SELECT MAX(total_cost) FROM TotalBeerCost) AS max_beer_cost,
    COUNT(DISTINCT cs.c_custkey) AS customer_count
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey AND rs.rn <= 5
LEFT JOIN 
    lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey))
LEFT JOIN 
    AvgSalesPerCustomer cs ON cs.c_custkey = l.l_orderkey
JOIN 
    part p ON p.p_partkey = l.l_partkey
GROUP BY 
    n.n_name, 
    p.p_name, 
    r.r_name
HAVING 
    COUNT(DISTINCT l.l_orderkey) > (SELECT AVG(customer_count) FROM (SELECT COUNT(DISTINCT o.o_orderkey) AS customer_count FROM orders o GROUP BY o.o_custkey) AS subquery)
ORDER BY 
    total_lineitem_value DESC, 
    n.n_name, 
    p.p_name;
