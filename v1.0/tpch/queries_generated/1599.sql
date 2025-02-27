WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
           COUNT(DISTINCT ps.ps_partkey) AS PartCount
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), 
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS TotalOrderValue,
           COUNT(o.o_orderkey) AS OrderCount
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
NationPerformance AS (
    SELECT n.n_nationkey, n.n_name, COALESCE(SUM(sd.TotalCost), 0) AS SupplierCost, 
           COALESCE(SUM(cd.TotalOrderValue), 0) AS CustomerValue
    FROM nation n
    LEFT JOIN SupplierDetails sd ON n.n_nationkey = sd.s_nationkey
    LEFT JOIN CustomerOrders cd ON n.n_nationkey = (SELECT cs.c_nationkey FROM customer cs WHERE cs.c_custkey = cd.c_custkey)
    GROUP BY n.n_nationkey, n.n_name
)
SELECT np.n_name, np.SupplierCost, np.CustomerValue,
       CASE WHEN np.SupplierCost > np.CustomerValue THEN 'Supplier Dominant'
            WHEN np.SupplierCost < np.CustomerValue THEN 'Customer Dominant'
            ELSE 'Balanced' END AS Performance
FROM NationPerformance np
WHERE np.SupplierCost IS NOT NULL OR np.CustomerValue IS NOT NULL
ORDER BY np.SupplierCost DESC, np.CustomerValue DESC;
