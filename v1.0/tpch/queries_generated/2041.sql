WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        ps.ps_availqty,
        ps.ps_supplycost,
        (ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_totalprice,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FinalResults AS (
    SELECT 
        cs.c_name,
        cs.order_count,
        po.p_name,
        po.total_supply_cost,
        CASE 
            WHEN cs.order_count > 5 THEN 'High'
            WHEN cs.order_count BETWEEN 3 AND 5 THEN 'Medium'
            ELSE 'Low'
        END AS order_frequency,
        COALESCE(ss.supplier_total_cost, 0) AS supplier_cost
    FROM 
        CustomerOrders cs
    LEFT JOIN 
        PartDetails po ON po.p_partkey IN (SELECT ps.p_partkey FROM partsupp ps WHERE ps.ps_availqty > 10)
    LEFT JOIN 
        SupplierSummary ss ON ss.supplier_total_cost > 10000
    WHERE 
        cs.order_count IS NOT NULL
)
SELECT 
    r.c_name,
    r.order_count,
    r.p_name,
    r.total_supply_cost,
    r.order_frequency,
    r.supplier_cost
FROM 
    FinalResults r
WHERE 
    r.supplier_cost IS NOT NULL 
    AND r.order_frequency = 'High'
ORDER BY 
    r.order_count DESC, r.total_supply_cost ASC;
