WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_value
    FROM 
        part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
),
TopRegions AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_regionkey, r.r_name
    HAVING 
        COUNT(DISTINCT s.s_suppkey) > 5
)
SELECT 
    co.c_custkey,
    co.total_spent,
    tsi.total_supply_value,
    ts.r_name AS region_name,
    COALESCE(rs.s_name, 'No Supplier') AS supplier_name
FROM 
    CustomerOrders co
LEFT JOIN PartSupplierInfo tsi ON co.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n JOIN supplier s ON n.n_nationkey = s.s_nationkey WHERE s.s_suppkey = rs.s_suppkey LIMIT 1))
LEFT JOIN RankedSuppliers rs ON co.c_custkey = rs.s_suppkey
JOIN TopRegions ts ON ts.n_regionkey = (SELECT n.n_regionkey FROM nation n JOIN supplier s ON n.n_nationkey = s.s_nationkey WHERE s.s_suppkey = rs.s_suppkey LIMIT 1)
WHERE 
    co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
ORDER BY 
    co.total_spent DESC;
