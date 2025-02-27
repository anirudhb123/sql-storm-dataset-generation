WITH RECURSIVE CustomerOrderHierarchy AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS order_level
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    
    UNION ALL

    SELECT 
        coh.c_custkey,
        coh.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        coh.order_level + 1
    FROM 
        CustomerOrderHierarchy coh
    JOIN 
        orders o ON coh.o_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND
        o.o_orderdate < CURRENT_DATE - INTERVAL '1 year'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
RegionSupplier AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(sd.total_supply_cost) AS total_cost_across_suppliers
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        SupplierDetails sd ON s.s_suppkey = sd.s_suppkey
    GROUP BY 
        r.r_name
)
SELECT 
    COALESCE(r.region_name, 'Unknown Region') AS region_name,
    COALESCE(rs.supplier_count, 0) AS supplier_count,
    COALESCE(rs.total_cost_across_suppliers, 0.00) AS total_cost_across_suppliers,
    COUNT(DISTINCT coh.o_orderkey) AS total_orders,
    AVG(coh.o_totalprice) AS avg_order_value
FROM 
    RegionSupplier rs
FULL OUTER JOIN 
    CustomerOrderHierarchy coh ON rs.region_name = (SELECT r.r_name FROM region r JOIN nation n ON r.r_regionkey = n.n_regionkey WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = coh.c_custkey))
GROUP BY 
    r.region_name
HAVING 
    AVG(coh.o_totalprice) > (SELECT AVG(o.o_totalprice) FROM orders o WHERE o.o_orderstatus = 'O')
ORDER BY 
    total_cost_across_suppliers DESC, region_name ASC;
