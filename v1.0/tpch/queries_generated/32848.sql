WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_nationkey, 
        o.o_orderkey, 
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
    
    UNION ALL

    SELECT 
        ch.c_custkey, 
        ch.c_name, 
        ch.c_nationkey, 
        o.o_orderkey, 
        ROW_NUMBER() OVER (PARTITION BY ch.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        CustomerHierarchy ch
    JOIN 
        orders o ON ch.o_orderkey <> o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O'
),

PartSupplier AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),

RecentOrders AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE_ADD(CURRENT_DATE, INTERVAL -30 DAY)
    GROUP BY 
        l.l_orderkey, l.l_partkey
)

SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    COALESCE(SUM(po.total_value), 0) AS total_order_value,
    AVG(ps.avg_supply_cost) AS avg_supply_price,
    MAX(ch.order_rank) AS max_order_rank
FROM 
    nation n
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    CustomerHierarchy ch ON c.c_custkey = ch.c_custkey
LEFT JOIN 
    RecentOrders po ON ch.o_orderkey = po.l_orderkey
LEFT JOIN 
    PartSupplier ps ON po.l_partkey = ps.ps_partkey
WHERE 
    n.n_comment IS NOT NULL AND 
    (c.c_name LIKE '%Inc%' OR c.c_address LIKE '%Street%')
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10
ORDER BY 
    total_order_value DESC, 
    customer_count DESC;
