
WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        DENSE_RANK() OVER (ORDER BY c.c_acctbal DESC) AS rank_acctbal,
        COUNT(o.o_orderkey) AS total_orders 
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
),
FilteredCustomers AS (
    SELECT 
        rc.c_custkey,
        rc.c_name,
        rc.c_acctbal,
        rc.total_orders
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rank_acctbal <= 10 AND rc.total_orders > 5
),
CustomerParts AS (
    SELECT 
        fc.c_custkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        FilteredCustomers fc
    JOIN 
        orders o ON fc.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        fc.c_custkey, p.p_name
)
SELECT 
    fc.c_custkey,
    fc.c_name,
    fc.c_acctbal,
    LISTAGG(cp.p_name, ', ') WITHIN GROUP (ORDER BY cp.p_name) AS purchased_parts,
    SUM(cp.part_count) AS total_parts_purchased
FROM 
    FilteredCustomers fc
JOIN 
    CustomerParts cp ON fc.c_custkey = cp.c_custkey
GROUP BY 
    fc.c_custkey, fc.c_name, fc.c_acctbal
ORDER BY 
    fc.c_acctbal DESC;
