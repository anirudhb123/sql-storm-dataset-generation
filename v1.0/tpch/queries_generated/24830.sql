WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn,
        COUNT(*) OVER (PARTITION BY o.o_orderstatus) AS total_orders
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
),
Supp_Costs AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supplycost,
        COUNT(DISTINCT ps.ps_suppkey) as unique_suppliers
    FROM 
        partsupp ps
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 10000
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_mfgr,
        COALESCE(NULLIF(p.p_container, ''), 'UNKNOWN') AS container,
        p.p_size,
        CASE 
            WHEN p.p_retailprice IS NULL THEN 0 
            ELSE p.p_retailprice 
        END AS retail_price
    FROM 
        part p
)
SELECT 
    r.r_name,
    SUM(CASE WHEN li.l_returnflag = 'R' THEN li.l_extendedprice ELSE 0 END) AS returned_amount,
    SUM(li.l_extendedprice) AS total_sales,
    AVG(pc.total_spent) AS avg_customer_spending,
    MAX(su.total_supplycost) AS highest_supply_cost,
    COUNT(DISTINCT co.c_custkey) AS number_of_customers
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem li ON ps.ps_partkey = li.l_partkey
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = (SELECT MIN(c.c_custkey) FROM customer c WHERE c.c_nationkey = n.n_nationkey)
LEFT JOIN 
    Supp_Costs su ON ps.ps_partkey = su.ps_partkey
LEFT JOIN 
    PartDetails pc ON ps.ps_partkey = pc.p_partkey
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name
ORDER BY 
    returned_amount DESC, total_sales ASC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
