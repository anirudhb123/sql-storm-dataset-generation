WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_availqty,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spending,
        COUNT(o.o_orderkey) AS total_orders,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.custkey
)
SELECT 
    r.n_nationkey, 
    r.r_name, 
    COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
    SUM(CASE WHEN p.rank <= 10 THEN p.total_availqty ELSE 0 END) AS top_part_availqty,
    AVG(cs.total_spending) AS avg_customer_spending
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedParts p ON s.s_suppkey = p.s_suppkey
LEFT JOIN 
    CustomerOrders cs ON s.s_suppkey = cs.c_custkey
WHERE 
    r.r_comment IS NOT NULL
GROUP BY 
    r.n_nationkey, r.r_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    avg_customer_spending DESC;
