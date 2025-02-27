WITH ranked_orders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate, 
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2023-01-01'
), 

supplier_nation AS (
    SELECT 
        s.s_suppkey,
        n.n_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, n.n_name
), 

top_part_supp AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        partsupp ps
    WHERE 
        EXISTS (
            SELECT 1 
            FROM supplier s 
            WHERE s.s_suppkey = ps.ps_suppkey AND s.s_acctbal IS NOT NULL
                  AND s.s_acctbal >= (
                        SELECT AVG(s2.s_acctbal) 
                        FROM supplier s2 
                        WHERE s2.s_nationkey IN (1, 2)
                    )
        )
    GROUP BY 
        ps.ps_partkey
)

SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_retailprice, 
    sn.n_name AS supplier_nation, 
    sn.part_count,
    CASE 
        WHEN ro.order_rank <= 5 THEN 'Top Order'
        ELSE 'Other Order'
    END AS order_category,
    ts.total_avail_qty,
    (CASE 
         WHEN ts.total_avail_qty IS NULL THEN 'No Availability'
         ELSE 'Available'
     END) AS availability_status
FROM 
    part p
LEFT JOIN 
    supplier_nation sn ON EXISTS (
        SELECT 1 
        FROM supplier s 
        WHERE s.s_suppkey IN (
            SELECT ps.ps_suppkey 
            FROM partsupp ps 
            WHERE ps.ps_partkey = p.p_partkey
        )
    )
LEFT JOIN 
    ranked_orders ro ON ro.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey 
        AND l.l_returnflag = 'N'
    )
LEFT JOIN 
    top_part_supp ts ON ts.ps_partkey = p.p_partkey
WHERE 
    p.p_size IN (SELECT DISTINCT (CASE WHEN p_size < 10 THEN 5 ELSE 10 END) FROM part)
    AND (p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) OR p.p_container IS NOT NULL)
ORDER BY 
    p.p_partkey;
