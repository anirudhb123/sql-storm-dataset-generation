WITH RECURSIVE SupplyChain AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s_acctbal) FROM supplier WHERE s_country = 'USA'
        )
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RegionSummary AS (
    SELECT 
        r.r_regionkey,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey
)
SELECT 
    sc.s_name AS supplier_name, 
    sc.p_name AS part_name, 
    sc.ps_availqty AS available_quantity,
    co.c_name AS customer_name,
    co.total_spent AS total_spent,
    rs.nation_count,
    rs.total_acctbal,
    COALESCE(NULLIF(sc.ps_supplycost, 0), 1) AS supply_cost_adjusted,
    CASE 
        WHEN sc.rank = 1 THEN 'Top Supplier' 
        ELSE 'Supplier'
    END AS supplier_category
FROM 
    SupplyChain sc
FULL OUTER JOIN 
    CustomerOrders co ON sc.s_suppkey = co.c_custkey
JOIN 
    RegionSummary rs ON sc.s_suppkey = rs.nation_count
WHERE 
    (sc.ps_availqty > 100 OR co.total_spent IS NOT NULL)
    AND (sc.ps_supplycost IS NOT NULL OR co.total_spent > 0)
ORDER BY 
    sc.s_name, co.total_spent DESC;
