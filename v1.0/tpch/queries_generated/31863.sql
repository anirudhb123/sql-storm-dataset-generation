WITH RECURSIVE SupplyChain AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        p.p_partkey, 
        p.p_name, 
        ps.ps_availqty, 
        ps.ps_supplycost, 
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 1000
),
MaxOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > (
            SELECT AVG(total_price) 
            FROM (
                SELECT 
                    SUM(l_extendedprice * (1 - l_discount)) AS total_price
                FROM 
                    lineitem
                GROUP BY 
                    l_orderkey
            ) AS avg_order
        )
),
SupplierRegion AS (
    SELECT 
        n.n_name AS nation_name, 
        r.r_name AS region_name, 
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_name, r.r_name
),
FinalResults AS (
    SELECT 
        sc.s_suppkey,
        sc.s_name,
        sc.p_partkey,
        sc.p_name,
        (sc.ps_availqty * sc.ps_supplycost) AS supply_value,
        sr.nation_name,
        sr.region_name,
        mo.total_price
    FROM 
        SupplyChain sc
    LEFT JOIN 
        SupplierRegion sr ON sc.s_suppkey = sr.supplier_count
    JOIN 
        MaxOrders mo ON mo.total_price > 100000
    WHERE 
        sc.rnk = 1
)
SELECT 
    fr.s_suppkey, 
    fr.s_name,
    fr.p_partkey, 
    fr.p_name, 
    fr.supply_value, 
    fr.nation_name, 
    fr.region_name, 
    COALESCE(fr.total_price, 0) AS order_total_price
FROM 
    FinalResults fr
ORDER BY 
    fr.supply_value DESC, 
    fr.total_price DESC;
