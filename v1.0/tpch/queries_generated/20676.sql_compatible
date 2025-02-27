
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        CASE 
            WHEN o.o_totalprice IS NULL THEN 'No Price'
            WHEN o.o_totalprice < 1000 THEN 'Low Value'
            ELSE 'High Value'
        END AS price_category
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
),
PartLineItems AS (
    SELECT 
        p.p_partkey, 
        COUNT(li.l_linenumber) AS lineitem_count,
        AVG(li.l_extendedprice) AS avg_extended_price
    FROM 
        part p
    LEFT JOIN 
        lineitem li ON p.p_partkey = li.l_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    cl.c_name,
    SUM(cl.o_totalprice) AS total_order_price,
    COALESCE(MAX(rs.total_supplycost), 0) AS max_supply_cost,
    SUM(CASE WHEN pli.lineitem_count > 0 THEN 1 ELSE 0 END) AS part_lineitem_count,
    STRING_AGG(DISTINCT CAST(pli.avg_extended_price AS VARCHAR), ', ') AS avg_extended_prices,
    MAX(CASE WHEN cl.price_category = 'No Price' THEN 1 ELSE 0 END) AS no_price_flag
FROM 
    CustomerOrders cl
JOIN 
    RankedSuppliers rs ON cl.c_custkey = 
        (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey IN 
            (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = 0) LIMIT 1)
LEFT JOIN 
    PartLineItems pli ON pli.p_partkey = 
        (SELECT p.p_partkey FROM part p ORDER BY RANDOM() LIMIT 1)
GROUP BY 
    cl.c_name
HAVING 
    SUM(cl.o_totalprice) > 5000 OR MAX(pli.lineitem_count) <= 0
ORDER BY 
    total_order_price DESC NULLS LAST;
