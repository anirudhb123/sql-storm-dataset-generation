WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2021-01-01' AND 
        o.o_orderdate < DATE '2022-01-01'
),
part_supplier AS (
    SELECT 
        p.p_name,
        ps.ps_supplycost,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        part p 
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_name, ps.ps_supplycost
    HAVING 
        SUM(ps.ps_availqty) > 0
),
customer_nation AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name,
        c.c_acctbal
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        c.c_acctbal > 10000
)
SELECT 
    cn.n_name AS nation_name,
    COUNT(DISTINCT co.o_orderkey) AS order_count,
    ROUND(AVG(co.o_totalprice), 2) AS avg_order_price,
    COALESCE(SUM(ps.total_available * ps.ps_supplycost), 0) AS total_supply_cost,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM 
    customer_nation cn
LEFT JOIN 
    ranked_orders co ON cn.c_custkey = co.o_custkey AND co.order_rank <= 5
LEFT JOIN 
    part_supplier ps ON ps.ps_supplycost < cn.c_acctbal
WHERE 
    cn.n_name IS NOT NULL
GROUP BY 
    cn.n_name
ORDER BY 
    avg_order_price DESC; 
