WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spending,
        1 AS order_level
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name

    UNION ALL

    SELECT 
        co.c_custkey,
        co.c_name,
        SUM(o.o_totalprice) AS total_spending,
        co.order_level + 1 
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        co.c_custkey, co.c_name, co.order_level
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
PartStatistics AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY p.p_retailprice) AS median_price
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    c.c_name,
    co.total_spending,
    ps.avg_supply_cost,
    ps.supplier_count,
    s.total_supplycost
FROM 
    CustomerOrders co
JOIN 
    PartStatistics ps ON co.c_custkey = (
        SELECT 
            o.o_custkey 
        FROM 
            orders o 
        WHERE 
            o.o_orderkey = (
                SELECT 
                    MAX(o2.o_orderkey) 
                FROM 
                    orders o2 
                WHERE 
                    o2.o_custkey = co.c_custkey
            )
    )
JOIN 
    SupplierSummary s ON s.s_suppkey = (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_partkey = ps.p_partkey 
        ORDER BY 
            ps.ps_availqty DESC 
        LIMIT 1
    )
WHERE 
    co.total_spending IS NOT NULL
AND 
    ps.avg_supply_cost > 100
ORDER BY 
    co.total_spending DESC, ps.supplier_count ASC;
