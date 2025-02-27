WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
), 
CustomerOrderSummary AS (
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
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supp_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)

SELECT 
    p.p_name,
    p.p_brand,
    COALESCE(psd.total_cost, 0) AS total_cost,
    CASE 
        WHEN psd.supp_count IS NULL THEN 'No suppliers'
        ELSE CONCAT(psd.supp_count, ' suppliers available')
    END AS supplier_availability,
    c.total_spent,
    CASE 
        WHEN c.order_count > 0 THEN c.order_count
        ELSE NULL
    END AS total_orders,
    rn.largest_supply AS most_valuable_supplier
FROM 
    part p
LEFT JOIN 
    PartSupplierDetails psd ON p.p_partkey = psd.ps_partkey
LEFT JOIN 
    CustomerOrderSummary c ON c.c_custkey = (
        SELECT 
            o.o_custkey 
        FROM 
            orders o 
        WHERE 
            o.o_orderkey = (
                SELECT MAX(o_o.orderkey) 
                FROM orders o_o 
                JOIN lineitem l ON o_o.o_orderkey = l.l_orderkey
                WHERE 
                    l.l_partkey = p.p_partkey
            )
        LIMIT 1
    )
LEFT JOIN (
    SELECT 
        sr.s_suppkey,
        SUM(ps.ps_supplycost) AS largest_supply
    FROM 
        RankedSuppliers sr
    LEFT JOIN 
        partsupp ps ON sr.s_suppkey = ps.ps_suppkey
    WHERE 
        sr.rn = 1
    GROUP BY 
        sr.s_suppkey
) rn ON rn.s_suppkey = (SELECT MAX(s.s_suppkey) FROM supplier s WHERE s.s_nationkey = c.c_nationkey)
WHERE 
    (p.p_size = ANY (ARRAY[10, 20, 30]) OR p.p_retailprice IS NULL)
ORDER BY 
    total_cost DESC, 
    supplier_availability, 
    p.p_name;
