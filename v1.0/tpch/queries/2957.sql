WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerStats AS (
    SELECT 
        c.c_nationkey,
        COUNT(c.c_custkey) AS customer_count,
        SUM(c.c_acctbal) AS total_acct_balance
    FROM 
        customer c
    GROUP BY 
        c.c_nationkey
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    AVG(s.total_available) AS avg_available_qty,
    cs.customer_count,
    cs.total_acct_balance
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    orders o ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey)
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierAvailability s ON l.l_partkey = s.ps_partkey
LEFT JOIN 
    CustomerStats cs ON n.n_nationkey = cs.c_nationkey
GROUP BY 
    n.n_name, r.r_name, cs.customer_count, cs.total_acct_balance
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC, nation_name ASC;