WITH ranked_orders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        SUM(l.l_quantity) AS total_quantity, 
        COUNT(DISTINCT l.l_suppkey) AS supplier_count, 
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey 
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus
),
supplier_regions AS (
    SELECT 
        n.n_name AS nation_name, 
        r.r_name AS region_name, 
        s.s_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey 
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    GROUP BY 
        n.n_name, r.r_name, s.s_suppkey
)
SELECT 
    o.o_orderkey, 
    o.o_totalprice, 
    o.total_quantity, 
    sr.nation_name, 
    sr.region_name, 
    sr.total_supply_cost
FROM 
    ranked_orders o
JOIN 
    supplier_regions sr ON o.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = sr.nation_name))
    )
WHERE 
    o.order_rank <= 10
ORDER BY 
    o.o_orderkey;