WITH RECURSIVE SupplyChain AS (
    SELECT 
        ps_partkey, 
        ps_suppkey, 
        ps_availqty, 
        ps_supplycost,
        1 AS level
    FROM 
        partsupp
    WHERE 
        ps_availqty > 0
    
    UNION ALL
    
    SELECT 
        ps.partkey, 
        ps.suppkey, 
        ps.availqty - SC.availqty AS updated_availqty, 
        PS.supplycost,
        SC.level + 1
    FROM 
        partsupp ps
    INNER JOIN 
        SupplyChain SC ON ps.ps_partkey = SC.ps_partkey
    WHERE 
        ps.ps_availqty < SC.updated_availqty
    AND 
        level < 5
),
RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER(PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank,
        SUM(l.l_extendedprice) OVER (PARTITION BY o.o_orderkey) AS total_lineitem_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01'
        AND l.l_shipmode = 'AIR'
),
SupplierDetails AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.s_acctbal > (
            SELECT 
                AVG(s2.s_acctbal) 
            FROM 
                supplier s2 
            WHERE 
                s2.s_acctbal IS NOT NULL
        )
)
SELECT 
    s.s_name,
    s.s_acctbal,
    o.o_orderkey,
    o.total_lineitem_price,
    COALESCE(SC.ps_availqty, 0) AS available_qty,
    CASE 
        WHEN o.order_rank <= 5 THEN 'Top Order' ELSE 'Regular Order' 
    END AS order_category
FROM 
    SupplierDetails s
LEFT JOIN 
    RankedOrders o ON s.s_acctbal > o.o_totalprice
LEFT JOIN 
    SupplyChain SC ON o.o_orderkey = SC.ps_partkey
WHERE 
    s.region_name IS NOT NULL 
    OR o.o_orderdate IS NULL
ORDER BY 
    s.s_acctbal DESC, 
    o.o_orderkey ASC;
