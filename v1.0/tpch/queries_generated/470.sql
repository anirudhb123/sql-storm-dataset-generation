WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS total_lineitems,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_totalprice
),
RankedOrders AS (
    SELECT 
        o.*, 
        RANK() OVER (ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        OrderDetails o
)
SELECT 
    s.s_name,
    s.nation_name,
    s.total_cost,
    COUNT(DISTINCT r.o_orderkey) AS total_orders,
    AVG(o.o_totalprice) AS avg_order_value,
    MAX(CASE WHEN r.order_rank <= 5 THEN r.o_totalprice ELSE NULL END) AS top_order_value
FROM 
    SupplierDetails s
LEFT JOIN 
    RankedOrders r ON s.s_suppkey IN (
        SELECT DISTINCT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT l.l_partkey 
            FROM lineitem l 
            WHERE l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
        )
    )
LEFT JOIN 
    OrderDetails o ON r.o_orderkey = r.o_orderkey
GROUP BY 
    s.s_name, s.nation_name, s.total_cost
HAVING 
    total_orders > 0
ORDER BY 
    total_cost DESC;
