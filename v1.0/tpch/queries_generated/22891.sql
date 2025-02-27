WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_per_nation
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL 
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_linenumber) AS total_items,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS most_recent_order
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.custkey
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL 
),
PartSupply AS (
    SELECT 
        ps.ps_partkey,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_available
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
TopNationSuppliers AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        RankedSuppliers s ON n.n_nationkey = s.s_nationkey
    WHERE 
        s.rank_per_nation = 1
    GROUP BY 
        r.r_name
)
SELECT 
    c.c_custkey,
    c.c_name,
    COALESCE(r.revenue, 0) AS total_revenue,
    p.p_name,
    ps.total_available,
    tn.supplier_count,
    (CASE 
        WHEN c.custkey IS NULL THEN 'Undefined'
        ELSE 'Defined'
    END) AS cust_status,
    RANK() OVER (ORDER BY COALESCE(r.revenue, 0) DESC) AS revenue_rank
FROM 
    FilteredCustomers c
LEFT JOIN 
    RecentOrders r ON c.c_custkey = r.o_custkey AND r.most_recent_order = 1
LEFT JOIN 
    PartSupply ps ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p)
JOIN 
    TopNationSuppliers tn ON c.c_nationkey = tn.supplier_count
WHERE 
    EXTRACT(MONTH FROM r.o_orderdate) IN (1, 12)
ORDER BY 
    revenue_rank, c.custkey DESC NULLS LAST;
