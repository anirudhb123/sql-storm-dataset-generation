WITH RankedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_linenumber,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        l.l_returnflag,
        l.l_linestatus,
        l.l_shipdate,
        l.l_commitdate,
        l.l_receiptdate,
        l.l_shipinstruct,
        l.l_shipmode,
        l.l_comment,
        RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rnk
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2023-01-01' AND l.l_shipdate < DATE '2024-01-01'
),
TotalOrderCost AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_cost,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts,
        COUNT(DISTINCT l.l_suppkey) AS distinct_suppliers
    FROM 
        orders o
    JOIN 
        RankedLineItems l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.rnk = 1
    GROUP BY 
        o.o_orderkey
)
SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT c.c_custkey) AS customers_count,
    SUM(t.total_cost) AS total_revenue,
    AVG(t.distinct_parts) AS avg_parts_per_order,
    AVG(t.distinct_suppliers) AS avg_suppliers_per_order
FROM 
    TotalOrderCost t
JOIN 
    customer c ON c.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = t.o_orderkey)
JOIN 
    supplier s ON s.s_suppkey IN (SELECT l.l_suppkey FROM lineitem l WHERE l.l_orderkey = t.o_orderkey)
JOIN 
    nation n ON n.n_nationkey = c.c_nationkey
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC;
