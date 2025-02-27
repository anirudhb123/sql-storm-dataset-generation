WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost) AS total_supply_cost,
        DENSE_RANK() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name, 
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
RelevantOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS net_revenue
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -12, CURRENT_DATE) 
        AND o.o_orderstatus IN ('F', 'O')
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    r.r_name,
    ns.n_name,
    CASE 
        WHEN hs.customer_rank <= 5 THEN 'High Value'
        ELSE 'Standard'
    END AS customer_segment,
    COUNT(DISTINCT ro.o_orderkey) AS order_count,
    AVG(RL.total_supply_cost) AS avg_supplier_cost,
    SUM(ro.net_revenue) AS total_net_revenue
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation ns ON s.s_nationkey = ns.n_nationkey
JOIN 
    region r ON ns.n_regionkey = r.r_regionkey
LEFT JOIN 
    HighValueCustomers hs ON s.s_nationkey = hs.c_nationkey
LEFT JOIN 
    RelevantOrders ro ON ro.o_orderkey = (
        SELECT 
            o_orderkey 
        FROM 
            orders 
        WHERE 
            o_orderdate = (
                SELECT 
                    MAX(o_orderdate) 
                FROM 
                    orders 
                WHERE 
                    o_orderdate < ro.o_orderdate
                    AND o_orderkey IN (SELECT o_orderkey FROM lineitem WHERE l_partkey = ps.ps_partkey)
                )
            LIMIT 1)
LEFT JOIN 
    RankedSuppliers RL ON s.s_suppkey = RL.s_suppkey
WHERE 
    p.p_size BETWEEN 1 AND 100
    AND p.p_retailprice IS NOT NULL
GROUP BY 
    ps.ps_partkey, p.p_name, r.r_name, ns.n_name, hs.customer_rank
ORDER BY 
    total_net_revenue DESC, avg_supplier_cost ASC;
