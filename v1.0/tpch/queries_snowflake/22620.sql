
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
), 
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2) THEN 'High Value'
            ELSE 'Regular'
        END AS cust_segment
    FROM 
        customer c
), 
OrdersWithDiscount AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_discounted_price,
        o.o_orderstatus
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
), 
RegionSupplier AS (
    SELECT 
        r.r_regionkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(AVG(ps.ps_supplycost * ps.ps_availqty), 0) AS avg_supply_cost,
    r.supplier_count,
    COALESCE(SUM(oc.total_discounted_price), 0) AS total_order_value,
    CASE 
        WHEN COALESCE(AVG(ps.ps_supplycost * ps.ps_availqty), 0) > 1000 AND r.supplier_count > 5 THEN 'Highly Supplied'
        ELSE 'Low Supply'
    END AS supply_status,
    LISTAGG(DISTINCT c.c_name, ', ') AS customer_names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey AND rs.rnk <= 3
LEFT JOIN 
    OrdersWithDiscount oc ON oc.o_orderkey = ps.ps_partkey
LEFT JOIN 
    RegionSupplier r ON r.r_regionkey = (SELECT MAX(r_regionkey) FROM region)
LEFT JOIN 
    HighValueCustomers c ON c.c_custkey = oc.o_orderkey
GROUP BY 
    p.p_partkey, p.p_name, r.supplier_count
HAVING 
    COUNT(DISTINCT c.c_custkey) > 1
ORDER BY 
    total_order_value DESC, supply_status;
