WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
), 
OrderLineItems AS (
    SELECT 
        lo.l_orderkey,
        SUM(CASE WHEN lo.l_returnflag = 'R' THEN lo.l_extendedprice * (1 - lo.l_discount) ELSE 0 END) AS returned_value,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_value,
        COUNT(lo.l_orderkey) AS total_lines
    FROM 
        lineitem lo
    GROUP BY 
        lo.l_orderkey
), 
CustomerAggregates AS (
    SELECT 
        c.c_custkey,
        SUM(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice ELSE 0 END) AS open_orders_value,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        partsupp ps ON ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_name LIKE 'PERCENT%')
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name, 
    r.r_comment,
    coalesce(SUM(oa.open_orders_value), 0) AS total_open_order_value,
    COUNT(DISTINCT lo.l_orderkey) AS distinct_orders,
    CASE 
        WHEN COUNT(DISTINCT lo.l_orderkey) = 0 THEN NULL
        ELSE AVG(la.total_lines::DECIMAL) 
    END AS avg_lines_per_order,
    COUNT(DISTINCT ra.o_orderkey) AS ranking_orders
FROM 
    nation n 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    CustomerAggregates oa ON oa.c_custkey = n.n_nationkey
LEFT JOIN 
    OrderLineItems la ON la.l_orderkey = (SELECT o.o_orderkey FROM RankedOrders o WHERE o.order_rank = 1 AND o.o_orderstatus = 'O')
LEFT JOIN 
    RankedOrders ra ON ra.o_orderkey = la.l_orderkey
WHERE 
    r.r_name NOT LIKE '%West%'
    AND (oa.open_orders_value > 50000 OR r.r_comment IS NOT NULL)
GROUP BY 
    r.r_name, r.r_comment
ORDER BY 
    total_open_order_value DESC, r.r_name
HAVING 
    COUNT(DISTINCT lo.l_orderkey) > 0
