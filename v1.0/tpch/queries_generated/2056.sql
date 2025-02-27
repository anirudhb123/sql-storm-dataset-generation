WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT p.p_partkey) AS total_parts,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_available,
        s.total_parts,
        CASE 
            WHEN s.total_available > 1000 THEN 'High'
            WHEN s.total_available BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low' 
        END AS availability_level
    FROM 
        SupplierStats s
)
SELECT 
    rs.s_name,
    rs.total_available,
    rs.total_parts,
    rs.availability_level,
    os.total_orders,
    os.total_spent,
    COALESCE(os.spending_rank, 'Not Ranked') AS spending_rank
FROM 
    RankedSuppliers rs
LEFT JOIN 
    OrderSummary os ON rs.s_suppkey = os.c_custkey
WHERE 
    rs.total_parts > 10
ORDER BY 
    rs.availability_level DESC, 
    os.total_spent DESC;
