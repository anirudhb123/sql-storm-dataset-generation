WITH AvgOrderValue AS (
    SELECT 
        o_custkey,
        AVG(o_totalprice) AS avg_order_price
    FROM 
        orders
    WHERE 
        o_orderdate >= DATE '1996-01-01' AND o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o_custkey
),
SupplierCost AS (
    SELECT 
        ps_partkey,
        ps_suppkey,
        SUM(ps_supplycost * ps_availqty) AS total_cost
    FROM 
        partsupp
    GROUP BY 
        ps_partkey, ps_suppkey
),
CustomerNation AS (
    SELECT 
        c.c_custkey,
        n.n_name AS nation_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
)
SELECT 
    cn.nation_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_returns,
    AVG(a.avg_order_price) AS customer_avg_order_value,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', sp.total_cost, ')'), ', ') AS suppliers_costs
FROM 
    orders o
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    CustomerNation cn ON o.o_custkey = cn.c_custkey
LEFT JOIN 
    SupplierCost sp ON l.l_partkey = sp.ps_partkey
LEFT JOIN 
    supplier s ON sp.ps_suppkey = s.s_suppkey
LEFT JOIN 
    AvgOrderValue a ON o.o_custkey = a.o_custkey
WHERE 
    o.o_orderstatus = 'O' AND
    l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
GROUP BY 
    cn.nation_name
ORDER BY 
    total_orders DESC, total_returns ASC;