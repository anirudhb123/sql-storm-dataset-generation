WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
), 
SalesData AS (
    SELECT 
        o.o_orderkey,
        l.l_partkey,
        l.l_extendedprice * (1 - l.l_discount) AS net_price,
        c.c_mktsegment,
        l.l_shipdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
        AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
), 
AggregatedSales AS (
    SELECT
        s.p_partkey,
        SUM(sd.net_price) AS total_sales,
        COUNT(sd.o_orderkey) AS order_count
    FROM 
        RankedSuppliers rs
    JOIN 
        part s ON rs.ps_partkey = s.p_partkey
    LEFT JOIN 
        SalesData sd ON s.p_partkey = sd.l_partkey
    GROUP BY 
        s.p_partkey
)

SELECT
    p.p_name,
    COALESCE(as.total_sales, 0) AS total_sales,
    COALESCE(as.order_count, 0) AS order_count,
    rs.s_name AS top_supplier,
    rs.rank
FROM 
    part p
LEFT JOIN 
    AggregatedSales as ON p.p_partkey = as.p_partkey
LEFT JOIN 
    RankedSuppliers rs ON p.p_partkey = rs.ps_partkey AND rs.rank = 1
WHERE 
    p.p_size > 10
    OR p.p_container LIKE '%BOX%'
ORDER BY 
    total_sales DESC, 
    p.p_name ASC;
