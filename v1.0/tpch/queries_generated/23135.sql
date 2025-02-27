WITH RecursiveCustSales AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_sales,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_within_nation
    FROM 
        customer AS c
    LEFT JOIN 
        orders AS o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_nationkey
), 
TopNations AS (
    SELECT 
        n.n_name, 
        SUM(r.total_sales) AS total_nation_sales
    FROM 
        nation AS n
    JOIN 
        RecursiveCustSales AS r ON n.n_nationkey = (SELECT c.c_nationkey FROM customer AS c WHERE c.c_custkey = r.c_custkey LIMIT 1)
    GROUP BY 
        n.n_nationkey, n.n_name
), 
SupplierPartStats AS (
    SELECT 
        p.p_partkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available
    FROM 
        part AS p
    JOIN 
        partsupp AS ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier AS s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part AS p2) 
    GROUP BY 
        p.p_partkey, s.s_name
)
SELECT 
    n.n_name,
    ns.total_nation_sales,
    COALESCE(NULLIF(ss.s_name, ''), 'UNKNOWN SUPPLIER') AS supplier,
    ss.total_available
FROM 
    TopNations AS ns
LEFT JOIN 
    SupplierPartStats AS ss ON ns.total_nation_sales > (SELECT AVG(total_sales) FROM RecursiveCustSales)
JOIN 
    nation AS n ON n.n_name = ns.n_name
WHERE 
    ss.total_available IS NULL AND n.r_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA') 
ORDER BY 
    ns.total_nation_sales DESC;
