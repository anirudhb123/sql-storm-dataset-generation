
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND l.l_shipdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
)
SELECT 
    n.n_name,
    COALESCE(SUM(ss.total_sales), 0) AS total_sales_by_nation,
    COUNT(os.o_orderkey) AS total_orders,
    AVG(os.order_total) AS average_order_value,
    MAX(os.order_total) AS max_order_value
FROM 
    nation n
LEFT JOIN 
    SupplierSales ss ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = ss.s_suppkey)
LEFT JOIN 
    OrderSummary os ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = os.o_custkey)
GROUP BY 
    n.n_name
ORDER BY 
    total_sales_by_nation DESC, 
    n.n_name ASC
LIMIT 10;
