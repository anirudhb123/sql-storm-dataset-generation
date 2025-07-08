WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
AvailableParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_availqty) > 0
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'Account balance is NULL'
            ELSE CAST(s.s_acctbal AS varchar(20))
        END AS formatted_balance
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL OR s.s_comment LIKE '%important%'
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL AND COUNT(o.o_orderkey) > 0
)
SELECT 
    COALESCE(rd.o_orderkey, 0) AS order_key,
    rd.o_orderdate,
    COALESCE(rd.o_totalprice, 0) AS total_price,
    COALESCE(cu.c_name, 'Unknown Customer') AS customer_name,
    p.p_name,
    sa.formatted_balance,
    pa.total_available
FROM 
    RankedOrders rd
LEFT JOIN 
    CustomerOrders cu ON rd.o_orderkey = cu.c_custkey
LEFT JOIN 
    lineitem l ON rd.o_orderkey = l.l_orderkey
LEFT JOIN 
    part p ON l.l_partkey = p.p_partkey
LEFT JOIN 
    AvailableParts pa ON p.p_partkey = pa.ps_partkey
LEFT JOIN 
    SupplierDetails sa ON l.l_suppkey = sa.s_suppkey
WHERE 
    EXISTS (
        SELECT 1
        FROM region r
        JOIN nation n ON r.r_regionkey = n.n_regionkey
        WHERE n.n_nationkey = (SELECT DISTINCT c.c_nationkey FROM customer c WHERE c.c_custkey = cu.c_custkey)
        AND r.r_name = 'ASIA'
    )
ORDER BY 
    rd.o_orderdate DESC
LIMIT 100;