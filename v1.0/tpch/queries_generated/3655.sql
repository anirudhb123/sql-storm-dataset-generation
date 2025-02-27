WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    r.p_name,
    r.total_cost,
    fc.c_name,
    os.revenue,
    CASE 
        WHEN os.revenue IS NULL THEN 'No Revenue' 
        ELSE 'Revenue Found' 
    END AS revenue_status
FROM 
    RankedParts r
LEFT JOIN 
    FilteredCustomers fc ON r.rank = 1
LEFT JOIN 
    OrderSummary os ON fc.c_custkey = os.o_custkey
WHERE 
    r.total_cost > 1000
ORDER BY 
    r.total_cost DESC, fc.c_name;
