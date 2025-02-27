WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY SUM(ps.ps_availqty * ps.ps_supplycost) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.n_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        total_supply_cost,
        part_count
    FROM 
        SupplierStats
    WHERE 
        rn = 1 AND part_count > 5
)
SELECT 
    cs.c_custkey,
    cs.order_count,
    cs.total_spent,
    fs.s_name AS top_supplier,
    fs.part_count AS supplier_part_count
FROM 
    CustomerOrders cs
LEFT JOIN 
    FilteredSuppliers fs ON fs.s_suppkey = (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_partkey IN (SELECT p.p_partkey FROM lineitem l JOIN part p ON l.l_partkey = p.p_partkey WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey))
        GROUP BY ps.ps_suppkey
        ORDER BY SUM(ps.ps_availqty * ps.ps_supplycost) DESC
        LIMIT 1
    )
WHERE 
    cs.order_count > 0 
ORDER BY 
    cs.total_spent DESC, 
    cs.c_custkey ASC;
