WITH SupplierParts AS (
    SELECT s.s_name, p.p_name, p.p_size, ps.ps_availqty, ps.ps_supplycost, 
           CONCAT(s.s_name, ' supplies ', p.p_name, ' in size ', CAST(p.p_size AS VARCHAR), 
                  ' with availability of ', CAST(ps.ps_availqty AS VARCHAR), 
                  ' at a cost of ', CAST(ps.ps_supplycost AS VARCHAR), '.') AS supply_info
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
RegionSuppliers AS (
    SELECT r.r_name, sp.supply_info, COUNT(sp.supply_info) AS num_supplies
    FROM SupplierParts sp
    JOIN nation n ON sp.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY r.r_name, sp.supply_info
),
RankedSupplies AS (
    SELECT r.r_name, r.supply_info, r.num_supplies,
           ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY r.num_supplies DESC) AS rank
    FROM RegionSuppliers r
)
SELECT r.r_name, r.supply_info, r.num_supplies
FROM RankedSupplies r
WHERE r.rank <= 5
ORDER BY r.r_name, r.num_supplies DESC;
