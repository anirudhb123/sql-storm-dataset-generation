WITH SupplierAggregate AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS nation_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
RevenueByNation AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(os.o_totalprice) AS total_revenue
    FROM 
        OrderSummary os
    JOIN 
        nation n ON os.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(SA.total_supply_value, 0) AS total_supply_value,
    RBN.total_revenue,
    (p.p_retailprice * COALESCE(SA.part_count, 0)) AS estimated_value,
    CASE 
        WHEN RBN.total_revenue IS NULL THEN 'No Sales'
        WHEN RBN.total_revenue > 100000 THEN 'High Revenue'
        ELSE 'Standard Revenue'
    END AS revenue_status
FROM 
    part p
LEFT JOIN 
    SupplierAggregate SA ON EXISTS (
        SELECT 1 
        FROM partsupp ps 
        WHERE ps.ps_partkey = p.p_partkey AND ps.ps_availqty > 0
    )
LEFT JOIN 
    RevenueByNation RBN ON RBN.n_nationkey = (
        SELECT n.n_nationkey 
        FROM nation n 
        JOIN supplier s ON s.s_nationkey = n.n_nationkey
        WHERE s.s_suppkey = (
            SELECT DISTINCT ps.ps_suppkey 
            FROM partsupp ps 
            WHERE ps.ps_partkey = p.p_partkey 
            ORDER BY ps.ps_supplycost DESC 
            LIMIT 1
        )
        LIMIT 1
    )
WHERE 
    p.p_size > 10 AND 
    (p.p_comment LIKE '%fragile%' OR p.p_mfgr != 'ManufacturerA')
ORDER BY 
    estimated_value DESC;
