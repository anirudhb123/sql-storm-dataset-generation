WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2 
            WHERE s2.s_nationkey = s.s_nationkey
        )
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_size IS NULL THEN 'Unknown Size'
            ELSE CONCAT(p.p_size, ' Units')
        END AS size_description
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS items_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey
),
RankedOrders AS (
    SELECT 
        os.o_orderkey,
        os.total_price,
        RANK() OVER (ORDER BY os.total_price DESC) AS order_rank
    FROM 
        OrderSummary os
)
SELECT 
    pd.p_name,
    sd.s_name,
    sd.nation_name,
    ro.total_price,
    ro.order_rank
FROM 
    PartDetails pd
LEFT OUTER JOIN 
    partsupp ps ON pd.p_partkey = ps.ps_partkey
LEFT OUTER JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    RankedOrders ro ON ro.o_orderkey = (
        SELECT o.o_orderkey
        FROM orders o
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
        WHERE l.l_partkey = pd.p_partkey
        ORDER BY o.o_orderdate DESC
        LIMIT 1
    )
WHERE 
    sd.s_acctbal IS NOT NULL 
ORDER BY 
    ro.total_price DESC, 
    pd.p_name;
