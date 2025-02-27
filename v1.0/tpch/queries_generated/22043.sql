WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn,
        CASE 
            WHEN p.p_size IS NULL THEN 'UNSIZED' 
            WHEN p.p_size < 10 THEN 'SMALL' 
            WHEN p.p_size BETWEEN 10 AND 20 THEN 'MEDIUM' 
            ELSE 'LARGE' 
        END AS size_category
    FROM 
        part p
), FeaturedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        COALESCE(s.s_comment, 'No Comment') AS comments
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2 
            WHERE s2.s_acctbal IS NOT NULL
        )
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        c.c_custkey, c.c_name
), ExpensiveLineItems AS (
    SELECT 
        li.l_orderkey, 
        li.l_partkey, 
        li.l_quantity * (1 - li.l_discount) AS net_price
    FROM 
        lineitem li
    WHERE 
        li.l_discount < 0.1
), OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        COUNT(li.l_orderkey) AS line_item_count, 
        SUM(li.l_extendedprice) AS total_price,
        MAX(li.l_discount) AS max_discount
    FROM 
        orders o
    LEFT JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey
)

SELECT 
    cp.c_name,
    rp.p_name,
    COALESCE(SUM(o.total_price), 0) AS total_order_value,
    SUM(CASE WHEN li.l_returnflag = 'R' THEN 1 ELSE 0 END) AS returned_items,
    AVG(li.l_discount) AS average_discount,
    COUNT(DISTINCT rp.p_partkey) AS part_count
FROM 
    CustomerOrders cp
JOIN 
    OrderSummary o ON cp.c_custkey = o.o_orderkey
JOIN 
    lineitem li ON li.l_orderkey = o.o_orderkey
JOIN 
    RankedParts rp ON li.l_partkey = rp.p_partkey
LEFT JOIN 
    FeaturedSuppliers fs ON li.l_suppkey = fs.s_suppkey
WHERE 
    cp.rank_spent <= 10
    AND rp.rn = 1
GROUP BY 
    cp.c_name, rp.p_name
HAVING 
    SUM(o.total_price) > (SELECT AVG(total_price) FROM OrderSummary)
ORDER BY 
    total_order_value DESC, 
    rp.p_name ASC;
