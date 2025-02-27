WITH regional_supplier_summary AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name, n.n_name
), customer_order_summary AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
), supplier_part_summary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    reg.region_name,
    reg.nation_name,
    cust.total_orders,
    cust.total_spent,
    supp.total_available_quantity,
    supp.average_supply_cost
FROM 
    regional_supplier_summary reg
JOIN 
    customer_order_summary cust ON reg.nation_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = cust.c_nationkey)
JOIN 
    supplier_part_summary supp ON supp.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_name LIKE '%Widget%')
WHERE 
    reg.supplier_count > 5 
    AND cust.total_orders > 10 
    AND supp.total_available_quantity > 50
ORDER BY 
    reg.region_name, reg.nation_name;
