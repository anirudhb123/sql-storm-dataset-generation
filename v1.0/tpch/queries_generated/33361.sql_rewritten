WITH RecursiveSalesSummary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 1000
),
TopSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 500
    GROUP BY 
        ps.ps_suppkey
    ORDER BY 
        total_supply_cost DESC
    LIMIT 5
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name
    FROM 
        nation n
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    ns.n_name AS nation_name,
    ns.r_name AS region_name,
    ts.total_supply_cost,
    COUNT(DISTINCT oss.c_custkey) AS total_customers,
    AVG(oss.total_spent) AS avg_spent_per_customer
FROM 
    TopSuppliers ts
JOIN 
    partsupp ps ON ts.ps_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    RecursiveSalesSummary oss ON oss.c_custkey = (
        SELECT 
            o.o_custkey 
        FROM 
            orders o 
        JOIN 
            customer c ON o.o_custkey = c.c_custkey 
        WHERE 
            o.o_orderkey IN (
                SELECT l.l_orderkey 
                FROM lineitem l 
                WHERE l.l_partkey = p.p_partkey
            )
        LIMIT 1
    )
JOIN 
    NationRegion ns ON ns.n_nationkey = (
        SELECT c.c_nationkey 
        FROM customer c 
        WHERE c.c_custkey = oss.c_custkey
    )
GROUP BY 
    ns.n_name, ns.r_name, ts.total_supply_cost
ORDER BY 
    avg_spent_per_customer DESC;