WITH RankedOrders AS (
    SELECT 
        o_orderkey,
        o_custkey,
        o_orderstatus,
        o_totalprice,
        o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) AS order_rank
    FROM 
        orders
), FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_avail_qty,
        MIN(CASE WHEN ps.ps_supplycost < 500 THEN ps.ps_supplycost ELSE NULL END) AS min_cost_under_500,
        STRING_AGG(CASE WHEN p.p_comment IS NOT NULL THEN p.p_comment ELSE 'No Comment' END, '; ') AS comments
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
), CustomerStats AS (
    SELECT
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date,
        SUM(CASE WHEN o.o_orderstatus <> 'O' THEN 1 ELSE 0 END) AS non_open_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
), Combined AS (
    SELECT 
        r.r_name,
        COALESCE(p.p_name, 'No Parts') AS part_name,
        cs.total_orders,
        cs.total_spent,
        p.total_avail_qty,
        p.min_cost_under_500,
        cs.non_open_orders,
        RANK() OVER (PARTITION BY r.r_name ORDER BY cs.total_spent DESC) AS rank_in_region
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        FilteredParts p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        CustomerStats cs ON cs.total_orders > 0
)
SELECT
    part_name,
    r_name,
    total_orders,
    total_spent,
    total_avail_qty,
    min_cost_under_500,
    non_open_orders
FROM 
    Combined
WHERE 
    rank_in_region <= 5 AND 
    (total_spent IS NOT NULL OR total_avail_qty > 0) AND
    COALESCE(min_cost_under_500, 1000) < 1000
ORDER BY 
    r_name, total_spent DESC;
