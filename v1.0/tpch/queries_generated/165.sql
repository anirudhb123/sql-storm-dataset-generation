WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost) AS supplier_rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > 0
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'No Balance'
            ELSE CONCAT('$', CAST(c.c_acctbal AS VARCHAR))
        END AS formatted_balance
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        n.n_name IS NOT NULL
)
SELECT 
    cd.c_name,
    cd.nation_name,
    oo.o_orderkey,
    oo.o_orderdate,
    sp.s_name,
    sp.ps_supplycost,
    sp.ps_availqty,
    cd.formatted_balance
FROM 
    CustomerDetails cd
LEFT JOIN 
    RankedOrders oo ON cd.c_custkey = oo.o_orderkey
LEFT JOIN 
    SupplierParts sp ON sp.supplier_rank = 1
WHERE 
    oo.order_rank <= 5
    OR (sp.ps_supplycost > 100.00 AND sp.ps_availqty < 50)
ORDER BY 
    cd.nation_name, 
    oo.o_orderdate DESC NULLS LAST;
