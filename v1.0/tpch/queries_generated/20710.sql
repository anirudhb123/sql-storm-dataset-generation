WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
), ExpensiveParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_comment,
        COUNT(DISTINCT ps.s_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice, p.p_comment
    HAVING 
        COUNT(DISTINCT ps.s_suppkey) > 5
), OrderStatistics AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        MAX(o.o_orderdate) AS last_order_date,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
), CustomerSegmentation AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS orders_count,
        CASE 
            WHEN SUM(o.o_totalprice) > 10000 THEN 'Platinum'
            WHEN SUM(o.o_totalprice) BETWEEN 5000 AND 10000 THEN 'Gold'
            WHEN SUM(o.o_totalprice) BETWEEN 1000 AND 5000 THEN 'Silver'
            ELSE 'Bronze'
        END AS segment
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
), OuterJoinResults AS (
    SELECT 
        coalesce(cs.c_custkey, 'Unknown') AS cust_key,
        coalesce(cs.total_spent, 0) AS total_spent,
        coalesce(esp.p_partkey, -1) AS part_key,
        esp.p_name,
        esp.p_retailprice,
        rs.s_name AS supplier_name,
        COALESCE(rn.rank, 'No Supplier') AS supplier_rank,
        os.revenue,
        os.last_order_date,
        os.line_item_count
    FROM 
        CustomerSegmentation cs
    FULL OUTER JOIN 
        ExpensiveParts esp ON cs.orders_count > 0
    LEFT JOIN 
        RankedSuppliers rs ON esp.p_partkey = rs.s_suppkey
    LEFT JOIN 
        OrderStatistics os ON cs.c_custkey = os.o_orderkey
)
SELECT 
    cust_key,
    total_spent,
    part_key,
    p_name,
    p_retailprice,
    supplier_name,
    supplier_rank,
    revenue,
    last_order_date,
    line_item_count
FROM 
    OuterJoinResults
WHERE 
    (supplier_rank IS NOT NULL OR part_key = -1)
    AND (total_spent > 1000 OR part_key = -1)
ORDER BY 
    total_spent DESC, part_key ASC NULLS LAST;
