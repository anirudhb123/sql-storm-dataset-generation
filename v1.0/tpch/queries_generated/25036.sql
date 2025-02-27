WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation,
        r.r_name AS region,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, n.n_name, r.r_name
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        n.n_name AS nation,
        c.c_acctbal,
        c.c_mktsegment,
        SUM(o.o_totalprice) AS total_orders_value
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_address, n.n_name, c.c_acctbal, c.c_mktsegment
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts,
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_discount) AS average_discount
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    sd.s_name AS supplier_name,
    cd.c_name AS customer_name,
    cd.nation AS customer_nation,
    ld.distinct_parts AS parts_count,
    ld.total_quantity AS total_line_quantity,
    cd.total_orders_value AS total_customer_orders_value,
    sd.total_supply_cost AS total_supplier_cost
FROM 
    SupplierDetails sd
JOIN 
    LineItemDetails ld ON ld.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = sd.nation)))
JOIN 
    CustomerDetails cd ON cd.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = ld.l_orderkey)
WHERE 
    sd.total_available_quantity > 100
ORDER BY 
    sd.s_name, cd.c_name;
