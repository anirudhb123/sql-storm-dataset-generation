WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS total_price_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
EligibleParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        MAX(ps.ps_supplycost) AS max_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    GROUP BY 
        p.p_partkey, p.p_name
),
FinalReport AS (
    SELECT 
        co.c_name,
        co.o_orderkey,
        co.o_totalprice,
        ep.p_name,
        rs.s_name AS top_supplier,
        co.total_price_rank,
        CASE
            WHEN rs.rnk = 1 THEN 'Top Supplier'
            ELSE 'Other Supplier'
        END AS supplier_status
    FROM 
        CustomerOrders co
    LEFT JOIN 
        RankedSuppliers rs ON rs.rnk <= 3 AND rs.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = co.c_custkey)
    CROSS JOIN 
        EligibleParts ep
    WHERE 
        co.o_totalprice IS NOT NULL
    AND 
        (ep.total_avail_qty > 0 OR ep.max_supply_cost IS NULL)
)
SELECT 
    f.c_name,
    f.o_orderkey,
    f.o_totalprice,
    f.p_name,
    COALESCE(f.top_supplier, 'No Supplier') AS effective_supplier,
    f.supplier_status
FROM 
    FinalReport f
WHERE 
    f.total_price_rank BETWEEN 1 AND 10
ORDER BY 
    f.o_totalprice DESC, 
    f.c_name ASC
LIMIT 1000;
