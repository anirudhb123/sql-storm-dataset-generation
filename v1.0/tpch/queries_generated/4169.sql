WITH RankedProviders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost * ps.ps_availqty AS total_value
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_availqty > 1000
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_spent,
        DENSE_RANK() OVER (ORDER BY co.total_spent DESC) AS customer_rank
    FROM 
        CustomerOrders co
    WHERE 
        co.total_spent > 5000
)
SELECT 
    n.n_name,
    COUNT(DISTINCT tp.p_partkey) AS total_parts,
    SUM(tp.total_value) AS total_part_value,
    MAX(s.s_acctbal) AS max_supplier_acctbal
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    HighValueParts tp ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = tp.p_partkey)
LEFT JOIN 
    RankedProviders rp ON s.s_suppkey = rp.s_suppkey
LEFT JOIN 
    TopCustomers tc ON tc.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = tp.p_partkey) LIMIT 1)
WHERE 
    rp.rn = 1 AND 
    (s.s_acctbal IS NOT NULL OR tp.total_value IS NULL)
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT tp.p_partkey) > 0 AND 
    SUM(tp.total_value) > 10000
ORDER BY 
    n.n_name;
