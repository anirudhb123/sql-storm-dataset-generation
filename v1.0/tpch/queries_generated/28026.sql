WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUBSTRING(s.s_comment, 1, 50) AS short_comment
    FROM supplier s
    WHERE LENGTH(s.s_comment) > 50
), 
NationDetails AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
), 
PartUsage AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
), 
CustomerOrders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_expenditure
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
)
SELECT 
    sd.s_name AS Supplier_Name,
    nd.n_name AS Nation_Name,
    nd.region_name AS Region,
    pu.total_supply_cost AS Total_Supply_Cost,
    co.total_expenditure AS Total_Expenditure,
    CASE 
        WHEN co.total_expenditure IS NULL THEN 'No Orders'
        WHEN pu.total_supply_cost > co.total_expenditure THEN 'High Supply Cost'
        ELSE 'Balanced'
    END AS Supply_Status
FROM SupplierDetails sd
JOIN NationDetails nd ON sd.s_nationkey = nd.n_nationkey
JOIN PartUsage pu ON pu.ps_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sd.s_suppkey)
LEFT JOIN CustomerOrders co ON sd.s_nationkey = co.c_custkey
ORDER BY Total_Supply_Cost DESC, Total_Expenditure ASC;
