WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_returnflag,
        RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS item_rank
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2023-01-01' AND l.l_returnflag = 'N'
),
FinalReport AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        COALESCE(ss.total_available, 0) AS total_available,
        COALESCE(ss.avg_supply_cost, 0) AS avg_supply_cost,
        COUNT(li.item_rank) AS number_of_items,
        MAX(li.l_extendedprice) AS max_item_price
    FROM 
        RankedOrders o
    LEFT JOIN SupplierStats ss ON ss.s_suppkey = (SELECT ps.ps_suppkey 
                                                    FROM partsupp ps 
                                                    WHERE ps.ps_partkey = ANY (SELECT l.l_partkey 
                                                                                FROM lineitem l 
                                                                                WHERE l.l_orderkey = o.o_orderkey))
    LEFT JOIN LineItemDetails li ON li.l_orderkey = o.o_orderkey
    WHERE 
        o.rn = 1
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, ss.total_available, ss.avg_supply_cost
)
SELECT 
    fr.o_orderkey,
    fr.o_orderdate,
    fr.o_totalprice,
    fr.total_available,
    fr.avg_supply_cost,
    fr.number_of_items,
    fr.max_item_price
FROM 
    FinalReport fr
ORDER BY 
    fr.o_orderdate DESC, fr.o_totalprice DESC;
