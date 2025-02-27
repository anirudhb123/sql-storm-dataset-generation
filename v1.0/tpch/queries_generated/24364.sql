WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS account_rank
    FROM 
        supplier s
), OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
), CustomerStatus AS (
    SELECT 
        c.c_custkey,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'No Balance' 
            WHEN c.c_acctbal < 1000 THEN 'Low Balance' 
            ELSE 'Healthy Balance' 
        END AS balance_status,
        COUNT(DISTINCT o.o_orderkey) AS orders_count
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_acctbal
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    cs.balance_status,
    os.total_revenue,
    os.avg_quantity,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY os.total_revenue DESC) AS revenue_rank
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.account_rank = 1
LEFT JOIN 
    OrderStats os ON ps.ps_partkey = os.o_orderkey
LEFT JOIN 
    CustomerStatus cs ON cs.orders_count > 0
WHERE 
    p.p_size IN (SELECT DISTINCT ps.ps_availqty FROM partsupp ps WHERE ps.ps_availqty IS NOT NULL)
    AND (s.s_acctbal IS NOT NULL OR cs.balance_status = 'No Balance')
ORDER BY 
    p.p_partkey ASC, 
    os.total_revenue DESC;
