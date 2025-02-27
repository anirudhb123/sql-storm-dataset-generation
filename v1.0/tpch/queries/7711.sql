WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
supply_summary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
combined_info AS (
    SELECT 
        ro.o_orderkey,
        ro.c_name AS customer_name,
        ro.o_orderdate,
        ss.total_available,
        ss.average_supply_cost
    FROM 
        ranked_orders ro
    LEFT JOIN 
        supply_summary ss ON ss.ps_partkey = (SELECT l.l_partkey 
                                                FROM lineitem l 
                                                WHERE l.l_orderkey = ro.o_orderkey 
                                                ORDER BY l.l_extendedprice DESC LIMIT 1)
    WHERE 
        ro.order_rank <= 10
)
SELECT 
    ci.o_orderkey,
    ci.customer_name,
    ci.o_orderdate,
    ci.total_available,
    ci.average_supply_cost
FROM 
    combined_info ci
WHERE 
    ci.total_available > 1000
ORDER BY 
    ci.o_orderdate DESC, ci.total_available DESC;
