WITH RECURSIVE PriceRank AS (
    SELECT 
        ps.partkey,
        ps.suppkey,
        ps.ps_supplycost,
        DENSE_RANK() OVER (PARTITION BY ps.partkey ORDER BY ps.ps_supplycost DESC) AS rank
    FROM 
        partsupp ps
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2022-01-01'
    GROUP BY 
        c.c_custkey, o.o_orderkey
), Nations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(SUM(ps.ps_supplycost), 0) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COALESCE(SUM(ps.ps_availqty), 0) > 0
), BizarreJoin AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        np.n_name AS nation_name
    FROM 
        part p
    LEFT JOIN 
        (SELECT DISTINCT n.n_name, ps.ps_availqty 
         FROM partsupp ps 
         JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
         JOIN nation n ON s.s_nationkey = n.n_nationkey
         WHERE ps.ps_availqty IS NOT NULL AND ps.ps_availqty > ANY (SELECT ps_availqty FROM partsupp)) np
    ON 
        p.p_partkey = np.ps_partkey
)
SELECT 
    co.c_custkey,
    co.total_sales,
    pr.partkey,
    pr.ps_supplycost,
    ns.region_name,
    GROUP_CONCAT(DISTINCT ns.n_name) AS nation_group,
    CASE WHEN co.total_sales > 10000 THEN 'High Value'
         WHEN co.total_sales IS NULL THEN 'No Sales'
         ELSE 'Regular Value' END AS customer_value
FROM 
    CustomerOrders co
JOIN 
    PriceRank pr ON co.c_custkey = pr.suppkey
JOIN 
    Nations ns ON co.c_custkey = ns.n_nationkey
LEFT JOIN 
    BizarreJoin bz ON pr.partkey = bz.p_partkey
WHERE 
    (pr.rank = 1 OR co.total_sales > 5000)
GROUP BY 
    co.c_custkey, co.total_sales, pr.partkey, pr.ps_supplycost, ns.region_name
ORDER BY 
    co.total_sales DESC, pr.ps_supplycost ASC NULLS LAST;
