WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CustomerStatus AS (
    SELECT 
        c.c_custkey,
        COALESCE(SUM(o.o_totalprice), 0) AS total_spent,
        COUNT(o.o_orderkey) AS orders_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
NationRevenue AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(o.total_revenue) AS nation_revenue
    FROM 
        nation n
    JOIN 
        CustomerStatus cs ON cs.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
    JOIN 
        OrderStats o ON o.unique_customers > 0
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name,
    COALESCE(n.nation_revenue, 0) AS total_revenue,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(ss.avg_supply_cost) AS avg_supply_cost
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey IN (SELECT p.ps_suppkey FROM partsupp p)
LEFT JOIN 
    CustomerStatus cs ON cs.total_spent > (SELECT AVG(total_spent) FROM CustomerStatus)
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT n.n_nationkey) > 0 OR COUNT(DISTINCT s.s_suppkey) = 0
ORDER BY 
    total_revenue DESC, supplier_count ASC;
