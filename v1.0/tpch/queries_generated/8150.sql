WITH RankedNations AS (
    SELECT 
        n.n_name AS nation_name, 
        r.r_name AS region_name, 
        SUM(s.s_acctbal) AS total_account_balance,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(s.s_acctbal) DESC) AS rn
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name, r.r_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
TopSellingProducts AS (
    SELECT 
        p.p_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_name
    ORDER BY 
        total_sales DESC
    LIMIT 10
)
SELECT 
    rn.nation_name, 
    rn.region_name, 
    hvc.c_name AS top_customer, 
    hvc.total_spent, 
    tsp.p_name AS top_product, 
    tsp.total_sales
FROM 
    RankedNations rn
JOIN 
    HighValueCustomers hvc ON rn.total_account_balance > 50000
JOIN 
    TopSellingProducts tsp ON tsp.total_sales > 10000
ORDER BY 
    rn.region_name, hvc.total_spent DESC;
