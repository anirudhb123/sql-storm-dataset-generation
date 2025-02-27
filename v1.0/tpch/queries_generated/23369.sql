WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND 
        o.o_orderdate < DATE '2023-12-31'
),
PartSuppliers AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM 
        partsupp ps
    INNER JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100.00
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND
        (LEFT(c.c_name, 1) BETWEEN 'A' AND 'M')
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    COALESCE(po.total_supply_cost, 0) AS supply_cost,
    COALESCE(co.total_spent, 0) AS customer_spending,
    CASE 
        WHEN co.order_count > 0 THEN 'Has Orders' 
        ELSE 'No Orders' 
    END AS order_status
FROM 
    part p
LEFT JOIN 
    PartSuppliers po ON p.p_partkey = po.ps_partkey
LEFT JOIN 
    CustomerOrders co ON p.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost = (SELECT MAX(ps_inner.ps_supplycost) FROM partsupp ps_inner WHERE ps_inner.ps_partkey = p.p_partkey) LIMIT 1)
WHERE 
    p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_mfgr LIKE '%Manufacturer%')
    AND p.p_comment IS NOT NULL
ORDER BY 
    p.p_name ASC
LIMIT 50;
