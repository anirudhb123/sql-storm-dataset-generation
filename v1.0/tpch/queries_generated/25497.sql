WITH StringAggregation AS (
    SELECT 
        p_name,
        STRING_AGG(DISTINCT CONCAT(s_name, ' from ', s_address), ', ') AS suppliers,
        COUNT(DISTINCT ps_suppkey) AS supplier_count,
        SUM(ps_availqty) AS total_available_quantity,
        SUM(ps_supplycost) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p_name
), OrderDetails AS (
    SELECT 
        c.c_name AS customer_name,
        o.o_orderdate,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
), Summary AS (
    SELECT 
        s.p_name,
        s.suppliers,
        s.supplier_count,
        s.total_available_quantity,
        s.total_supply_cost,
        od.customer_name,
        SUM(od.l_extendedprice * (1 - od.l_discount)) AS net_revenue
    FROM 
        StringAggregation s
    LEFT JOIN 
        OrderDetails od ON od.customer_name IS NOT NULL
    GROUP BY 
        s.p_name, s.suppliers, s.supplier_count, s.total_available_quantity, s.total_supply_cost, od.customer_name
)
SELECT 
    p_name,
    suppliers,
    supplier_count,
    total_available_quantity,
    total_supply_cost,
    COALESCE(SUM(net_revenue), 0) AS total_revenue
FROM 
    Summary
GROUP BY 
    p_name, suppliers, supplier_count, total_available_quantity, total_supply_cost
ORDER BY 
    total_revenue DESC;
