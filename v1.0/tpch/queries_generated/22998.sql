WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        s.s_name, 
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS supply_rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 1000
    GROUP BY 
        c.c_custkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        AVG(l.l_extendedprice) AS avg_price 
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        AVG(l.l_extendedprice) > (SELECT AVG(l_extendedprice) FROM lineitem)
)
SELECT 
    cs.c_custkey,
    COALESCE(RS.s_name, 'No Supplier') AS supplier_name,
    HP.p_name,
    HP.avg_price,
    cs.total_spent,
    cs.order_count,
    CASE 
        WHEN cs.last_order_date IS NULL THEN 'Never ordered'
        ELSE TO_CHAR(cs.last_order_date, 'YYYY-MM-DD')
    END AS last_order_date,
    CASE 
        WHEN RS.supp_rank = 1 THEN 'Top Supplier'
        ELSE 'Other Supplier'
    END AS supplier_category
FROM 
    CustomerOrderSummary cs
LEFT JOIN 
    RankedSuppliers RS ON cs.c_custkey = RS.ps_suppkey
JOIN 
    HighValueParts HP ON RS.ps_partkey = HP.p_partkey
WHERE 
    HP.avg_price IS NOT NULL
    AND (cs.total_spent IS NULL OR cs.total_spent > 500)
ORDER BY 
    cs.total_spent DESC NULLS LAST;
