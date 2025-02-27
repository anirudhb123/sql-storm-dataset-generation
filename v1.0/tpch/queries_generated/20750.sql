WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IS NULL OR o.o_orderstatus <> 'F'
    GROUP BY 
        c.c_custkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)

SELECT 
    r.r_name,
    cs.c_custkey,
    MAX(cs.order_count) AS max_orders,
    MIN(cs.total_spent) AS min_spent,
    pd.part_names,
    COALESCE(rs.s_name, 'No Supplier') AS top_supplier
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    CustomerOrders cs ON c.c_custkey = cs.c_custkey
LEFT JOIN 
    RankedSuppliers rs ON c.c_nationkey = rs.s_suppkey
LEFT JOIN 
    PartDetails pd ON cs.order_count > (SELECT AVG(order_count) FROM CustomerOrders)
WHERE 
    (c.c_acctbal + COALESCE(rs.s_acctbal, 0)) > 1000
GROUP BY 
    r.r_name, cs.c_custkey, pd.part_names, rs.s_name
ORDER BY 
    r.r_name, max_orders DESC, min_spent ASC;
