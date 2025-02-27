WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps.partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        r.s_suppkey,
        r.s_name,
        r.s_acctbal
    FROM 
        RankedSuppliers r
    WHERE 
        r.rank = 1
),
OrderSummary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
PartStats AS (
    SELECT 
        p.p_partkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(l.l_quantity) AS total_quantity_sold
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    c.c_custkey,
    c.c_name,
    coalesce(os.total_spent, 0) AS total_spent,
    coalesce(os.order_count, 0) AS order_count,
    p.p_partkey,
    p.p_name,
    COALESCE(ps.avg_supply_cost, 0) AS avg_supply_cost,
    COALESCE(ps.total_quantity_sold, 0) AS total_quantity_sold,
    CASE 
        WHEN p.p_retailprice > 100 THEN 'Expensive'
        ELSE 'Affordable'
    END AS price_category,
    (SELECT COUNT(*) FROM TopSuppliers) AS total_top_suppliers
FROM 
    customer c
LEFT JOIN 
    OrderSummary os ON c.c_custkey = os.c_custkey
LEFT JOIN 
    PartStats ps ON ps.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_availqty > 0)
JOIN 
    part p ON p.p_partkey = ps.p_partkey
WHERE 
    c.c_acctbal IS NOT NULL
ORDER BY 
    total_spent DESC, c.c_name ASC;
