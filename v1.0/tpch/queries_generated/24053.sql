WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk,
        SUM(ps.ps_supplycost * ps.ps_availqty) OVER (PARTITION BY ps.ps_suppkey) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT 
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        SUM(ps.ps_availqty * p.p_retailprice) AS total_value
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(rs.unique_parts, 0) AS unique_parts,
        COALESCE(rs.total_value, 0) AS total_value
    FROM 
        supplier s
    LEFT JOIN 
        SupplierParts rs ON s.s_suppkey = rs.ps_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_acctbal IS NOT NULL)
)
SELECT 
    co.c_custkey,
    co.c_name,
    ts.s_suppkey,
    ts.s_name,
    ts.unique_parts,
    ts.total_value,
    CASE
        WHEN ts.unique_parts > 10 THEN 'High Supply'
        ELSE 'Low Supply'
    END AS supply_category,
    COALESCE((SELECT AVG(l.l_extendedprice) FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)), 0) AS avg_order_value,
    CASE 
        WHEN EXISTS (SELECT 1 FROM region r WHERE r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = c.c_nationkey) AND r.r_name = 'EUROPE') 
        THEN 'European Customer'
        ELSE NULL 
    END AS customer_region
FROM 
    CustomerOrders co
JOIN 
    TopSuppliers ts ON ts.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand LIKE '%Brand%') LIMIT 1)
WHERE 
    co.total_spent > (
        SELECT AVG(total_spent) FROM CustomerOrders
    )
ORDER BY 
    co.order_count DESC, 
    ts.total_value DESC
LIMIT 50;
