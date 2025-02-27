WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL 
        AND s.s_acctbal >= 1000
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F') OR o.o_orderdate IS NULL
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(r.name, 'Unknown Region') AS region_name,
    cu.c_name AS customer_name,
    RANK() OVER (ORDER BY ps.total_avail_qty DESC) AS supplier_rank,
    CASE 
        WHEN cu.total_spent IS NULL THEN 'No Orders'
        ELSE FORMAT(cu.total_spent, 'C')
    END AS formatted_total_spent,
    (SELECT 
        COUNT(DISTINCT l.l_orderkey) 
     FROM 
        lineitem l 
     WHERE 
        l.l_partkey = p.p_partkey) AS total_lineitems,
    EXISTS (
        SELECT 1 
        FROM 
            supplier s2 
        WHERE 
            s2.s_acctbal < 0 
            AND s2.s_nationkey = n.n_nationkey
    ) AS has_debt_suppliers
FROM 
    part p
LEFT JOIN 
    PartSupplierInfo ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.rank = 1
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    CustomerOrders cu ON cu.c_custkey = 
        (SELECT 
            o.o_custkey 
         FROM 
            orders o 
         WHERE 
            o.o_orderkey = 
                (SELECT MAX(o2.o_orderkey) 
                 FROM orders o2 WHERE o2.o_orderdate < '2023-01-01')
        )
WHERE 
    p.p_retailprice > 50.00
ORDER BY 
    formatted_total_spent DESC NULLS LAST;
