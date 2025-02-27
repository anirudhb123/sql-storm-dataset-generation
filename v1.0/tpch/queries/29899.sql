WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        p.p_retailprice AS retail_price,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        p.p_comment AS part_comment,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
), RankedSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        sp.supplier_name,
        sp.part_name,
        sp.retail_price,
        sp.available_quantity,
        sp.supply_cost,
        sp.part_comment
    FROM SupplierParts sp
    JOIN nation n ON sp.supplier_name IN (SELECT s.s_name FROM supplier s WHERE s.s_nationkey = n.n_nationkey)
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE sp.rank <= 5
)
SELECT 
    region_name, 
    COUNT(*) AS top_suppliers_count,
    SUM(retail_price) AS total_retail_value,
    AVG(supply_cost) AS average_supply_cost
FROM RankedSuppliers
GROUP BY region_name
ORDER BY total_retail_value DESC, top_suppliers_count DESC;
