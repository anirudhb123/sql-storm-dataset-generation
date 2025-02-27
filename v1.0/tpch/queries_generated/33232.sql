WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_shippriority,
        1 AS level
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'

    UNION ALL

    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_shippriority,
        oh.level + 1 AS level
    FROM 
        orders o
    JOIN 
        OrderHierarchy oh ON oh.o_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O'
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT l.l_orderkey) AS order_count,
        AVG(l.l_extendedprice) AS avg_price
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
FinalReport AS (
    SELECT 
        cs.c_name,
        cs.order_count,
        SUM(ps.total_supply_value) AS total_supply_value,
        SUM(pd.avg_price) AS avg_price_per_part,
        ROW_NUMBER() OVER (PARTITION BY cs.c_custkey ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerOrderSummary cs
    LEFT JOIN 
        SupplierPerformance ps ON ps.s_suppkey = (
            SELECT ps_temp.ps_suppkey
            FROM partsupp ps_temp
            JOIN lineitem li ON ps_temp.ps_partkey = li.l_partkey
            WHERE li.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey)
            ORDER BY ps_temp.ps_supplycost DESC
            LIMIT 1
        )
    LEFT JOIN 
        PartDetails pd ON pd.order_count > 0
    GROUP BY 
        cs.c_custkey, cs.c_name, cs.order_count
    HAVING 
        SUM(pd.avg_price) IS NOT NULL
)
SELECT 
    fr.c_name,
    fr.order_count,
    COALESCE(fr.total_supply_value, 0) AS total_supply_value,
    COALESCE(fr.avg_price_per_part, 0) AS avg_price_per_part,
    fr.rank
FROM 
    FinalReport fr
WHERE 
    fr.rank <= 5
ORDER BY 
    fr.total_supply_value DESC;
