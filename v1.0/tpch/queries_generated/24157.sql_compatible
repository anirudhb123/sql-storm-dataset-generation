
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS RNK
    FROM 
        supplier s
),
CustomerOrderTotals AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        cmt.total_spent,
        ROW_NUMBER() OVER (ORDER BY cmt.total_spent DESC) AS rnk
    FROM 
        customer c
    JOIN 
        CustomerOrderTotals cmt ON c.c_custkey = cmt.c_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
        AND cmt.total_spent > 10000
),
SupplierPartStats AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
ExcessivelyCommentedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
    WHERE 
        LENGTH(p.p_comment) > 50
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        n.n_regionkey,
        r.r_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    cr.r_name AS region,
    COUNT(DISTINCT cus.c_custkey) AS high_value_customer_count,
    SUM(SUPS.total_supply_cost) AS total_supply_cost,
    AVG(SUPS.total_quantity) AS avg_quantity_per_part,
    STRING_AGG(DISTINCT pc.p_name, '; ') AS excessively_commented_parts
FROM 
    HighValueCustomers cus
JOIN 
    CustomerRegion cr ON cus.c_custkey = cr.c_custkey
LEFT JOIN 
    SupplierPartStats SUPS ON cus.c_custkey = SUPS.ps_partkey
LEFT JOIN 
    ExcessivelyCommentedParts pc ON SUPS.ps_partkey = pc.p_partkey
GROUP BY 
    cr.r_name
HAVING 
    COUNT(DISTINCT cus.c_custkey) > 0
    AND SUM(SUPS.total_supply_cost) IS NOT NULL
ORDER BY 
    high_value_customer_count DESC;
