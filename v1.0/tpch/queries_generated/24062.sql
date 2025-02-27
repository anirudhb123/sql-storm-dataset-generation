WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rank,
        p.p_partkey,
        p.p_retailprice,
        ps.ps_availqty,
        CASE 
            WHEN ps.ps_availqty IS NULL THEN 'Unavailable'
            ELSE 'Available'
        END AS availability
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
        AND s.s_acctbal > 10
),
TotalCustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 50
    GROUP BY 
        c.c_custkey
),
HighValueCustomers AS (
    SELECT 
        tc.c_custkey,
        tc.order_count,
        tc.total_spent,
        CASE 
            WHEN tc.total_spent > 1000 THEN 'High Value'
            ELSE 'Regular'
        END AS customer_type
    FROM 
        TotalCustomerOrders tc
    WHERE 
        tc.order_count > 5
)
SELECT 
    rs.s_name,
    rs.p_partkey,
    rs.p_retailprice,
    rs.availability,
    hvc.order_count,
    hvc.total_spent,
    hvc.customer_type
FROM 
    RankedSuppliers rs
JOIN 
    HighValueCustomers hvc ON rs.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = rs.s_suppkey ORDER BY ps.ps_supplycost DESC LIMIT 1)
WHERE 
    rs.rank = 1
  AND 
    hvc.customer_type = 'High Value'
ORDER BY 
    hvc.total_spent DESC,
    rs.p_retailprice ASC;
