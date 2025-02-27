WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER(PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS account_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
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
LineitemAggregates AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) as net_sales,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    COALESCE(SUM(sd.total_supply_cost), 0) AS total_supply_cost,
    COALESCE(SUM(co.total_spent), 0) AS total_spent,
    COUNT(DISTINCT lo.l_orderkey) AS total_orders,
    COUNT(DISTINCT sd.s_suppkey) AS total_suppliers,
    AVG(lp.avg_quantity) AS overall_avg_quantity
FROM 
    nation n
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    CustomerOrders co ON c.c_custkey = co.c_custkey
LEFT JOIN 
    SupplierDetails sd ON n.n_nationkey = sd.account_rank
LEFT JOIN 
    LineitemAggregates lo ON lo.l_orderkey = co.total_spent
LEFT JOIN 
    (SELECT DISTINCT ps_partkey, ps_availqty FROM partsupp WHERE ps_availqty IS NOT NULL) AS lp ON lp.ps_partkey IN (SELECT ps_partkey FROM partsupp)
WHERE 
    n.n_name IS NOT NULL
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 0
ORDER BY 
    n.n_name;
