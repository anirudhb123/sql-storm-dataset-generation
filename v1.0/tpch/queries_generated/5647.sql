WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND 
        o.o_orderdate < DATE '2023-01-01'
),
TopNationCustomers AS (
    SELECT 
        n.n_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        RankedOrders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.rank <= 10
    GROUP BY 
        n.n_nationkey, n.n_name
),
RegionPerformance AS (
    SELECT 
        r.r_name AS region, 
        SUM(t.total_spent) AS region_total_spent
    FROM 
        TopNationCustomers t
    JOIN 
        nation n ON t.n_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_name
)
SELECT 
    r.region, 
    r.region_total_spent, 
    RANK() OVER (ORDER BY r.region_total_spent DESC) AS performance_rank
FROM 
    RegionPerformance r
ORDER BY 
    r.region_total_spent DESC;
