WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        n.n_name AS customer_nation,
        RANK() OVER (PARTITION BY n.n_name ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
),
TopOrders AS (
    SELECT 
        *
    FROM 
        RankedOrders
    WHERE 
        order_rank <= 10
),
OrderLineItemSummaries AS (
    SELECT 
        to.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(DISTINCT li.l_partkey) AS unique_parts_count,
        COUNT(DISTINCT li.l_suppkey) AS unique_suppliers_count
    FROM 
        TopOrders to
    JOIN 
        lineitem li ON to.o_orderkey = li.l_orderkey
    GROUP BY 
        to.o_orderkey
)
SELECT 
    to.o_orderkey,
    to.o_orderdate,
    to.o_totalprice,
    ol.total_revenue,
    ol.unique_parts_count,
    ol.unique_suppliers_count,
    to.customer_nation
FROM 
    TopOrders to
JOIN 
    OrderLineItemSummaries ol ON to.o_orderkey = ol.o_orderkey
ORDER BY 
    to.customer_nation, ol.total_revenue DESC;
