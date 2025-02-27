WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o 
    WHERE 
        o.o_orderdate >= DATE '2021-01-01' 
        AND o.o_orderdate < DATE '2022-01-01'
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost * ps_availqty) FROM partsupp ps)
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey, 
        l.l_partkey, 
        l.l_quantity, 
        (l.l_extendedprice * (1 - l.l_discount)) AS net_price
    FROM 
        lineitem l 
    WHERE 
        l.l_shipdate >= '2021-06-01' 
        AND l.l_shipdate < '2021-12-01'
)
SELECT 
    r.r_name, 
    COUNT(DISTINCT coalesce(c.c_custkey, 0)) AS unique_customers, 
    SUM(COALESCE(fl.net_price, 0)) AS total_net_price,
    AVG(o.order_rank) AS avg_order_rank,
    STRING_AGG(DISTINCT s.s_name || ' (Total Value: ' || COALESCE(ts.total_supply_value, '0') || ')', ', ') AS suppliers_info
FROM 
    region r 
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey 
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey 
LEFT JOIN 
    RankedOrders o ON o.o_orderkey IN (SELECT l.l_orderkey FROM FilteredLineItems fl WHERE l.l_orderkey = o.o_orderkey)
LEFT JOIN 
    TopSuppliers ts ON ts.s_suppkey IN (SELECT l.l_suppkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5 
    AND SUM(COALESCE(fl.net_price, 0)) IS NOT NULL
ORDER BY 
    r.r_name;
