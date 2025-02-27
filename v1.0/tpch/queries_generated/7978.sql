WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_name, 
        c.c_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
),
TopOrders AS (
    SELECT 
        r.r_name AS region_name, 
        n.n_name AS nation_name, 
        AVG(o.o_totalprice) AS avg_order_value,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        RankedOrders o
    JOIN 
        supplier s ON s.s_suppkey = (SELECT ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 10))
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.rank <= 10
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    region_name, 
    nation_name, 
    avg_order_value, 
    total_orders,
    RANK() OVER (ORDER BY avg_order_value DESC) AS avg_order_rank
FROM 
    TopOrders
ORDER BY 
    avg_order_value DESC;
