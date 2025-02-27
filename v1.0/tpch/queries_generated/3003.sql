WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rnk
    FROM 
        part p
),
TotalSupplies AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '2023-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000
),
SupplierCount AS (
    SELECT 
        l.l_partkey, 
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
)

SELECT 
    rp.p_name,
    rp.p_retailprice,
    ts.total_avail_qty,
    tc.total_spent,
    sc.unique_suppliers
FROM 
    RankedParts rp
LEFT JOIN 
    TotalSupplies ts ON rp.p_partkey = ts.ps_partkey
LEFT JOIN 
    SupplierCount sc ON rp.p_partkey = sc.l_partkey
LEFT JOIN 
    TopCustomers tc ON tc.total_spent IS NOT NULL
WHERE 
    rp.rnk <= 5 AND 
    (ts.total_avail_qty IS NULL OR ts.total_avail_qty > 50) AND 
    (tc.total_spent IS NOT NULL OR tc.total_spent < 10000)
ORDER BY 
    rp.p_retailprice DESC;
