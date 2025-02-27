WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        DENSE_RANK() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS rank_by_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
CombinedStats AS (
    SELECT 
        ps.part_count,
        ps.avg_acctbal,
        co.order_count,
        co.total_spent,
        ps.s_name
    FROM 
        SupplierStats ps
    JOIN 
        CustomerOrders co ON ps.part_count > 5 AND co.total_spent > 1000
)
SELECT 
    cs.s_name,
    cs.part_count,
    cs.avg_acctbal,
    cs.order_count,
    cs.total_spent,
    COALESCE(rp.total_available, 0) AS total_available_parts,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Orders'
        WHEN cs.total_spent > 10000 THEN 'High Spender'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    CombinedStats cs
LEFT JOIN 
    RankedParts rp ON cs.part_count = rp.rank_by_cost
WHERE 
    cs.avg_acctbal IS NOT NULL OR cs.total_spent IS NOT NULL
ORDER BY 
    cs.total_spent DESC, cs.part_count ASC;
