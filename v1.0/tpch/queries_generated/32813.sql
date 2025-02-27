WITH RECURSIVE SupplyChain AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        0 AS level
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty IS NOT NULL

    UNION ALL

    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        ps.ps_availqty - 2 AS ps_availqty,
        ps.ps_supplycost * 1.1 AS ps_supplycost,
        level + 1
    FROM 
        SupplyChain sc
    JOIN 
        supplier s ON sc.s_suppkey = s.s_suppkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty IS NOT NULL AND 
        sc.level < 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F' OR o.o_orderstatus IS NULL
    GROUP BY 
        c.c_custkey, c.c_name
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(li.l_quantity) AS total_quantity,
        AVG(p.p_retailprice) AS avg_price
    FROM 
        part p
    JOIN 
        lineitem li ON p.p_partkey = li.l_partkey
    WHERE 
        li.l_shipdate >= '2023-01-01' AND 
        li.l_shipdate < '2023-10-01'
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    co.c_name,
    pd.p_name,
    pd.total_quantity,
    pd.avg_price,
    sc.ps_availqty,
    CASE 
        WHEN sc.ps_supplycost IS NULL THEN 'No cost available'
        ELSE CAST(sc.ps_supplycost AS CHAR(10))
    END AS supply_cost,
    ROW_NUMBER() OVER (PARTITION BY co.c_custkey ORDER BY pd.total_quantity DESC) AS rank
FROM 
    CustomerOrders co
JOIN 
    PartDetails pd ON pd.total_quantity > 10
LEFT OUTER JOIN 
    SupplyChain sc ON pd.p_partkey = sc.ps_partkey
WHERE 
    (sc.ps_availqty IS NOT NULL AND sc.ps_availqty > 0) OR pd.total_quantity > 20
ORDER BY 
    co.c_name, rank;
