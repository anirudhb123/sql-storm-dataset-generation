WITH SupplierParts AS (
    SELECT s.s_name AS Supplier_name, COUNT(ps.ps_partkey) AS Total_parts, 
           STRING_AGG(DISTINCT p.p_name, ', ') AS Part_names,
           SUM(ps.ps_availqty) AS Total_available_quantity,
           AVG(ps.ps_supplycost) AS Average_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_name
), 
RankedSuppliers AS (
    SELECT Supplier_name, Total_parts, Part_names, Total_available_quantity, 
           Average_supply_cost, 
           ROW_NUMBER() OVER (ORDER BY Total_parts DESC) AS Rank
    FROM SupplierParts
)
SELECT Rank, Supplier_name, Total_parts, Part_names, Total_available_quantity, 
       Average_supply_cost 
FROM RankedSuppliers 
WHERE Rank <= 10
ORDER BY Rank;
