WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rn,
        (SELECT COUNT(*) 
         FROM supplier 
         WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)) AS above_avg_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, s.s_name
),
FilteredSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT rs.s_name) AS supp_count,
        SUM(rs.total_avail_qty) AS total_available_quantity
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON rs.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rn = 1 AND 
        rs.total_avail_qty > 0
    GROUP BY 
        r.r_name, n.n_name
),
FinalOutput AS (
    SELECT 
        f.region_name,
        f.nation_name,
        f.supp_count,
        f.total_available_quantity,
        p.p_name,
        COALESCE(MIN(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE NULL END), 0) AS return_price,
        MAX(CASE WHEN l.l_discount IS NOT NULL THEN l.l_discount ELSE 0 END) AS max_discount
    FROM 
        FilteredSuppliers f
    LEFT JOIN 
        lineitem l ON l.l_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_partkey IN (SELECT ps_partkey FROM RankedSuppliers WHERE rn = 1))
    LEFT JOIN 
        part p ON p.p_partkey = l.l_partkey
    GROUP BY 
        f.region_name, f.nation_name, f.supp_count, f.total_available_quantity, p.p_name
)
SELECT 
    region_name, 
    nation_name, 
    supp_count, 
    total_available_quantity,
    p_name,
    (SELECT SUM(l_extendedprice) FROM lineitem WHERE l_orderkey IN 
     (SELECT o_orderkey FROM orders WHERE o_orderstatus = 'O' AND o_orderdate > CURRENT_DATE - INTERVAL '1 year')) AS total_extended_price_last_year,
    (SELECT COUNT(*) FROM orders WHERE o_totalprice IS NULL OR o_totalprice < 0) AS invalid_orders
FROM 
    FinalOutput
WHERE 
    total_available_quantity > (SELECT AVG(total_available_quantity) FROM FilteredSuppliers)
ORDER BY 
    region_name, nation_name, total_available_quantity DESC;
