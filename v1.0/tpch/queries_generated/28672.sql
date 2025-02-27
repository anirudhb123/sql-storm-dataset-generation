WITH SupplierDetails AS (
    SELECT 
        s.s_name, 
        s.s_address, 
        n.n_name AS nation_name, 
        r.r_name AS region_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        STRING_AGG(DISTINCT p.p_comment, '; ') AS comments_list
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 5000 AND
        r.r_name LIKE '%West%'
    GROUP BY 
        s.s_name, s.s_address, n.n_name, r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_name, 
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value,
        STRING_AGG(DISTINCT o.o_comment, '; ') AS order_comments
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_mktsegment = 'BUILDING'
    GROUP BY 
        c.c_name
)
SELECT 
    sd.s_name AS supplier_name,
    sd.total_parts,
    sd.total_supply_cost,
    COALESCE(cd.total_orders, 0) AS customer_total_orders,
    COALESCE(cd.total_spent, 0) AS customer_total_spent,
    COALESCE(cd.avg_order_value, 0) AS customer_avg_order_value,
    sd.comments_list,
    cd.order_comments
FROM 
    SupplierDetails sd
LEFT JOIN 
    CustomerOrders cd ON sd.nation_name = cd.c_name
ORDER BY 
    sd.total_supply_cost DESC, 
    cd.total_orders DESC
LIMIT 10;
