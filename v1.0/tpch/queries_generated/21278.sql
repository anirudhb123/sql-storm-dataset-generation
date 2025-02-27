WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER(PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS Rank
    FROM 
        supplier s
),
SupplierPartAvailability AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
EligibleParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr,
        p.p_type,
        p.p_size,
        CASE 
            WHEN p.p_retailprice IS NULL THEN 0 
            ELSE p.p_retailprice * 1.2 
        END AS adjusted_price
    FROM 
        part p 
    WHERE 
        p.p_size BETWEEN 1 AND 50
),

CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    ep.p_partkey, 
    ep.p_name, 
    ep.p_mfgr,
    ep.adjusted_price,
    COALESCE(sa.total_availqty, 0) AS total_supply_available,
    cs.order_count,
    cs.total_spent,
    CASE 
        WHEN cs.total_spent > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    EligibleParts ep
LEFT JOIN 
    SupplierPartAvailability sa ON ep.p_partkey = sa.ps_partkey
LEFT JOIN 
    CustomerOrderStats cs ON cs.order_count >= 10
WHERE 
    (EXISTS (SELECT 1 FROM RankedSuppliers rs WHERE rs.s_suppkey = sa.ps_suppkey AND rs.Rank = 1)
    OR sa.ps_partkey IS NULL)
ORDER BY 
    ep.adjusted_price DESC, cs.total_spent ASC;
