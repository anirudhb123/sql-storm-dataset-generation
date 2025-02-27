WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= (CURRENT_DATE - INTERVAL '1 year')
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopPartSupplies AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available 
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_availqty) > (SELECT AVG(ps2.ps_availqty) FROM partsupp ps2)
),
FinalReport AS (
    SELECT 
        c.c_name,
        coalesce(fo.total_orders, 0) AS total_orders,
        fo.total_spent,
        CASE 
            WHEN fo.total_spent BETWEEN 1000 AND 5000 THEN 'Medium Spender'
            WHEN fo.total_spent > 5000 THEN 'High Spender'
            ELSE 'Low Spender'
        END AS spending_category,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts_ordered
    FROM 
        CustomerOrderSummary fo
    LEFT JOIN 
        TopPartSupplies ps ON fo.total_orders > 0
    LEFT JOIN 
        supplier s ON ps.ps_partkey = (SELECT ps2.ps_partkey FROM partsupp ps2 ORDER BY ps2.ps_supplycost LIMIT 1)
    GROUP BY 
        c.c_name, fo.total_orders, fo.total_spent
)
SELECT 
    fr.c_name,
    fr.total_orders,
    fr.total_spent,
    fr.spending_category,
    COALESCE(r.rank, 0) AS order_rank,
    CASE 
        WHEN r.o_orderstatus = 'O' THEN 'Confirmed Order'
        WHEN r.o_orderstatus IS NULL THEN 'No Orders'
        ELSE 'Other Status'
    END AS order_status_description
FROM 
    FinalReport fr
LEFT JOIN 
    RankedOrders r ON fr.total_orders = r.rank
ORDER BY 
    fr.total_spent DESC, fr.c_name;
