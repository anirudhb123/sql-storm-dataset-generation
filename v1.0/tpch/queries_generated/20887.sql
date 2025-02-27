WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) as rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_totalprice IS NOT NULL
),
SupplierProducts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        ps.ps_partkey
),
CustomerRank AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        CASE 
            WHEN SUM(o.o_totalprice) > 10000 THEN 'VIP'
            WHEN SUM(o.o_totalprice) BETWEEN 5000 AND 10000 THEN 'Regular'
            ELSE 'New'
        END AS customer_status
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name, 
    COALESCE(s.total_supply_cost, 0) AS supply_cost,
    cr.customer_status,
    COUNT(ro.o_orderkey) AS orders_count
FROM 
    part p
LEFT JOIN 
    SupplierProducts s ON p.p_partkey = s.ps_partkey
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey IN (
        SELECT 
            l.l_orderkey 
        FROM 
            lineitem l 
        WHERE 
            l.l_partkey = p.p_partkey AND 
            l.l_returnflag = 'N'
    )
LEFT JOIN 
    CustomerRank cr ON cr.c_custkey = (
        SELECT 
            c.c_custkey 
        FROM 
            customer c 
        WHERE 
            c.c_name LIKE '%' || SUBSTRING(p.p_name, 1, 5) || '%'
        LIMIT 
            1
    )
WHERE 
    p.p_size IS NOT NULL AND 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
    AND 
    (SELECT COUNT(*) FROM nation WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA') AND n_comment IS NOT NULL) > 5
GROUP BY 
    p.p_partkey, p.p_name, s.total_supply_cost, cr.customer_status
HAVING 
    SUM(s.total_supply_cost) IS NOT NULL
ORDER BY 
    supply_cost DESC, orders_count DESC
LIMIT 10 OFFSET 5;
