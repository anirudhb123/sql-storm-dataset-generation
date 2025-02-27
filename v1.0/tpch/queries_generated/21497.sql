WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
AvailableParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        DENSE_RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
)
SELECT 
    cust.c_name,
    COALESCE(p.p_name, 'No Parts') AS part_name,
    COUNT(li.l_orderkey) AS total_line_items,
    SUM(COALESCE(li.l_extendedprice, 0)) AS total_revenue,
    AVG(li.l_discount) AS avg_discount,
    CASE 
        WHEN SUM(COALESCE(li.l_tax, 0)) = 0 THEN NULL 
        ELSE SUM(li.l_tax) / NULLIF(SUM(li.l_extendedprice), 0) 
    END AS tax_ratio,
    rs.s_name AS top_supplier
FROM 
    CustomerOrders cust
LEFT JOIN 
    lineitem li ON cust.o_orderkey = li.l_orderkey
LEFT JOIN 
    AvailableParts p ON li.l_partkey = p.p_partkey
LEFT JOIN 
    RankedSuppliers rs ON rs.rn = 1 AND rs.s_nationkey = cust.c_custkey
WHERE 
    (total_revenue IS NOT NULL OR cust.o_orderkey IS NULL)
GROUP BY 
    cust.c_name, p.p_name, rs.s_name
HAVING 
    SUM(li.l_quantity) > 0
ORDER BY 
    total_revenue DESC,
    cust.c_name;
