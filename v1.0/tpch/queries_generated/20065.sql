WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank_per_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
), 
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_supplycost) > 1000
), 
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
FilteredCustomers AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.total_spent,
        cs.order_count,
        CASE 
            WHEN cs.total_spent > 5000 THEN 'VIP' 
            ELSE 'Regular' 
        END AS customer_type
    FROM 
        CustomerStats cs
    WHERE 
        cs.total_spent IS NOT NULL
), 
DiscountedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice * (1 - AVG(l.l_discount) OVER (PARTITION BY o.o_orderkey)) AS discounted_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
)

SELECT 
    f.c_name AS customer_name,
    hs.rank_per_nation,
    p.p_name AS part_name,
    d.discounted_price,
    CASE 
        WHEN d.discounted_price IS NULL THEN 'No Order'
        ELSE 'Has Order'
    END AS order_status
FROM 
    FilteredCustomers f
LEFT JOIN 
    RankedSuppliers hs ON hs.s_name = f.c_name
LEFT JOIN 
    HighValueParts p ON p.p_partkey = (SELECT MAX(ps.ps_partkey) FROM partsupp ps WHERE ps.ps_supplycost < (SELECT MIN(ps2.ps_supplycost) FROM partsupp ps2 WHERE ps2.ps_partkey = p.p_partkey))
LEFT JOIN 
    DiscountedOrders d ON d.o_orderkey = (SELECT MIN(o2.o_orderkey) FROM orders o2 WHERE o2.o_custkey = f.c_custkey AND o2.o_orderstatus = 'O')
WHERE 
    f.order_count > 0
ORDER BY 
    customer_name, part_name;
