WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        CASE WHEN o.o_orderstatus = 'O' THEN 'Active' ELSE 'Inactive' END AS order_status_label
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = 'O') -- Only orders above average price
),
SuspiciousOrders AS (
    SELECT 
        fo.o_orderkey,
        COUNT(*) AS num_line_items,
        SUM(li.l_extendedprice) AS total_extended_price
    FROM 
        FilteredOrders fo
    JOIN 
        lineitem li ON fo.o_orderkey = li.l_orderkey
    WHERE 
        li.l_discount > 0.5 -- Potentially suspicious orders with high discounts
    GROUP BY 
        fo.o_orderkey
    HAVING 
        COUNT(*) > 3 -- More than 3 line items
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        COUNT(ps.ps_suppkey) AS supplier_count,
        MAX(ps.ps_supplycost) AS max_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    r.r_name AS region_name,
    COALESCE(ss.total_extended_price, 0) AS total_suspicious_sales,
    COUNT(DISTINCT s.rn) AS supplier_rankings,
    SUM(CASE WHEN ss.supplier_count > 1 THEN ss.max_supply_cost ELSE 0 END) AS total_cost_for_parts_with_multiple_suppliers,
    STRING_AGG(DISTINCT CONCAT('Supplier: ', su.s_name, ' (Key: ', su.s_suppkey, ')'), ', ') AS suppliers_list
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers su ON ps.ps_suppkey = su.s_suppkey
LEFT JOIN 
    nation n ON su.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    SuspiciousOrders ss ON ss.o_orderkey = ps.ps_partkey
WHERE 
    (SELECT COUNT(*) FROM FilteredOrders fo WHERE fo.o_orderstatus = 'O') >= 10 -- Ensure there are enough active orders
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, r.r_name
HAVING 
    COUNT(DISTINCT su.s_suppkey) > 2 -- More than 2 distinct suppliers
ORDER BY 
    total_suspicious_sales DESC, p.p_retailprice ASC;
