WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
ExpensiveParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice,
        CASE 
            WHEN p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) THEN 'Expensive' 
            ELSE 'Affordable' 
        END AS price_category
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 30
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent 
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    WHERE 
        o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL 
    GROUP BY 
        c.c_custkey
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        lineitem l 
    GROUP BY 
        l.l_orderkey 
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
FinalResults AS (
    SELECT 
        SUM(elo.total_spent) AS total_spent,
        COUNT(DISTINCT elo.c_custkey) AS unique_customers,
        AVG(CASE WHEN ep.price_category = 'Expensive' THEN ep.p_retailprice ELSE NULL END) AS avg_expensive_part_price,
        COUNT(DISTINCT rs.s_suppkey) AS unique_suppliers
    FROM 
        CustomerOrders elo
    LEFT JOIN 
        ExpensiveParts ep ON ep.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost > 50)
    LEFT JOIN 
        RankedSuppliers rs ON rs.rank <= 5
)
SELECT 
    fr.total_spent, 
    fr.unique_customers, 
    fr.avg_expensive_part_price, 
    fr.unique_suppliers,
    COALESCE(fr.total_spent, 0) + COALESCE(fr.avg_expensive_part_price * 5, 0) AS adjusted_total,
    CASE 
        WHEN fr.unique_customers > 100 THEN 'High Engagement' 
        ELSE 'Low Engagement' 
    END AS engagement_level
FROM 
    FinalResults fr
WHERE 
    fr.unique_suppliers IS NOT NULL 
ORDER BY 
    adjusted_total DESC;
