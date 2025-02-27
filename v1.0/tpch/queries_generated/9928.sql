WITH region_supplier AS (
    SELECT 
        r.r_name AS region_name,
        s.s_name AS supplier_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name, s.s_name
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_discount * l.l_extendedprice) AS total_discounted_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice
)
SELECT 
    rs.region_name,
    rs.supplier_name,
    os.o_orderkey,
    os.o_totalprice,
    os.total_discounted_price,
    (os.o_totalprice - os.total_discounted_price) AS final_price
FROM 
    region_supplier rs
JOIN 
    order_summary os ON rs.total_supply_cost > os.total_discounted_price
ORDER BY 
    rs.region_name, final_price DESC
LIMIT 100;
