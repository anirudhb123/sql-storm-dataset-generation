WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_order
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    COALESCE(n.n_name, 'Unknown') AS nation_name,
    p.p_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    MAX(o.o_totalprice) AS max_order_price,
    MIN(o.o_totalprice) AS min_order_price,
    AVG(o.o_totalprice) AS avg_order_price,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000 THEN 'High Sales'
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) BETWEEN 5000 AND 10000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    RankedOrders ro ON o.o_orderkey = ro.o_orderkey
WHERE 
    l.l_shipdate >= DATE '2022-01-01' AND l.l_shipdate < DATE '2023-01-01'
GROUP BY 
    n.n_name, p.p_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5 AND SUM(l.l_extendedprice * (1 - l.l_discount)) IS NOT NULL
ORDER BY 
    total_sales DESC, nation_name ASC;
