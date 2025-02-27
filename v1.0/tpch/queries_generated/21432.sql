WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        s.s_acctbal, 
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
PartTax AS (
    SELECT 
        l.l_partkey, 
        SUM(l.l_tax * l.l_extendedprice) AS total_tax,
        COUNT(l.l_returnflag) AS return_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate < CURRENT_DATE AND l.l_shipdate > CURRENT_DATE - INTERVAL '90 DAY'
    GROUP BY 
        l.l_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        STRING_AGG(DISTINCT o.o_orderstatus) AS order_statuses
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    COALESCE(rs.s_name, 'No Supplier') AS supplier_name,
    pt.total_tax, 
    co.total_spent,
    CASE 
        WHEN co.order_count IS NULL OR co.total_spent IS NULL THEN 'No Orders'
        ELSE 'Orders Present'
    END AS order_status,
    RANK() OVER (ORDER BY pt.total_tax DESC) AS tax_rank
FROM 
    part p
LEFT JOIN 
    RankedSuppliers rs ON p.p_partkey = rs.s_supplier_rank
LEFT JOIN 
    PartTax pt ON p.p_partkey = pt.l_partkey
FULL OUTER JOIN 
    CustomerOrders co ON p.p_partkey = co.c_custkey
WHERE 
    (pt.total_tax IS NOT NULL OR co.total_spent IS NOT NULL) 
AND 
    (p.p_retailprice > 10.00 OR p.p_size NOT BETWEEN 1 AND 50)
ORDER BY 
    tax_rank DESC NULLS LAST;
