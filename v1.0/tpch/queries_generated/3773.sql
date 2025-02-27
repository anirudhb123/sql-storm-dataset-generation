WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        p.p_brand,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, p.p_brand
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 1000
    GROUP BY 
        c.c_custkey, c.c_name
),
FinalResults AS (
    SELECT 
        co.c_name,
        co.total_spent,
        sp.total_supply_cost,
        so.o_orderkey,
        so.o_orderdate
    FROM 
        CustomerOrders co
    JOIN 
        RankedOrders so ON co.total_orders > 1
    LEFT JOIN 
        SupplierParts sp ON sp.ps_partkey IN (
            SELECT 
                l.l_partkey
            FROM 
                lineitem l 
            WHERE 
                l.l_orderkey = so.o_orderkey
        )
    WHERE 
        sp.supplier_count > 3
)
SELECT 
    fr.c_name,
    fr.total_spent,
    fr.total_supply_cost,
    fr.o_orderdate
FROM 
    FinalResults fr
WHERE 
    fr.total_spent IS NOT NULL 
ORDER BY 
    fr.total_spent DESC, fr.o_orderdate DESC
LIMIT 10;
