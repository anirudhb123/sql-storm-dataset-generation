WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
), 
AggregatedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        lineitem li
    JOIN 
        orders o ON li.l_orderkey = o.o_orderkey
    JOIN 
        partsupp ps ON li.l_partkey = ps.ps_partkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        p.p_partkey, p.p_name
), 
TopProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        a.total_sales,
        a.order_count,
        ROW_NUMBER() OVER (ORDER BY a.total_sales DESC) as product_rank
    FROM 
        AggregatedSales a
    JOIN 
        part p ON a.p_partkey = p.p_partkey
)
SELECT 
    r.o_orderkey,
    r.o_orderstatus,
    r.o_totalprice,
    r.o_orderdate,
    r.o_orderpriority,
    tp.p_name,
    tp.total_sales,
    tp.order_count
FROM 
    RankedOrders r
JOIN 
    TopProducts tp ON r.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = tp.p_partkey)
WHERE 
    r.order_rank <= 10 
    AND tp.product_rank <= 5
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;
