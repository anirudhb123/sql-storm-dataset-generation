WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(year, -1, GETDATE())
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS average_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    ss.total_available,
    ss.average_cost,
    hvc.total_spent,
    RANK() OVER (ORDER BY hs.total_spent DESC) AS customer_rank
FROM 
    part p
LEFT JOIN 
    SupplierStats ss ON p.p_partkey = ss.ps_partkey
LEFT JOIN 
    HighValueCustomers hvc ON hvc.total_spent IS NOT NULL
WHERE 
    (p.p_container LIKE '%BOX%' OR p.p_container LIKE '%PACK%')
    AND (ss.total_available IS NOT NULL OR hvc.c_custkey IS NULL)
ORDER BY 
    p.p_partkey
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
