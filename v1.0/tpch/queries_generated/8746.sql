WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND o.o_orderdate >= DATE '2023-01-01'
        AND o.o_orderdate < DATE '2023-10-01'
),
top_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.c_name,
        o.c_acctbal
    FROM 
        ranked_orders o
    WHERE 
        o.order_rank <= 5
),
order_line_items AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_line_value,
        COUNT(lo.l_linenumber) AS total_line_items
    FROM 
        lineitem lo
    WHERE 
        lo.l_shipdate >= DATE '2023-01-01'
        AND lo.l_shipdate < DATE '2023-10-01'
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    to.o_orderkey,
    to.o_orderdate,
    to.o_totalprice,
    to.c_name,
    to.c_acctbal,
    oli.total_line_value,
    oli.total_line_items
FROM 
    top_orders to
LEFT JOIN 
    order_line_items oli ON to.o_orderkey = oli.l_orderkey
ORDER BY 
    to.o_orderdate DESC, 
    to.o_totalprice DESC;
