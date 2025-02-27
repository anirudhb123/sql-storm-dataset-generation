WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2021-01-01' AND o.o_orderdate < DATE '2022-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 0
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        COALESCE(sp.total_available, 0) AS available_qty,
        COALESCE(sp.avg_supply_cost, 0) AS avg_cost
    FROM 
        part p
    LEFT JOIN 
        SupplierParts sp ON p.p_partkey = sp.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    ps.total_spent,
    CASE 
        WHEN ps.total_spent IS NOT NULL THEN 'Active Customer'
        ELSE 'Inactive Customer'
    END AS customer_status,
    CASE 
        WHEN R.order_rank <= 10 THEN 'Top 10 Order'
        ELSE 'Other Order'
    END AS order_category
FROM 
    PartSupplierDetails p
LEFT JOIN 
    CustomerOrders ps ON p.p_partkey IN (
        SELECT 
            l.l_partkey 
        FROM 
            lineitem l 
        JOIN 
            orders o ON l.l_orderkey = o.o_orderkey
        WHERE 
            o.o_orderdate BETWEEN DATE '2021-01-01' AND DATE '2022-01-01'
    )
LEFT JOIN 
    RankedOrders R ON R.o_orderkey = (
        SELECT 
            o.o_orderkey 
        FROM 
            orders o
        WHERE 
            o.o_orderdate BETWEEN DATE '2021-01-01' AND DATE '2022-01-01'
        ORDER BY 
            o.o_totalprice DESC 
        LIMIT 1
    )
WHERE 
    p.p_retailprice > 100.00
ORDER BY 
    p.p_partkey, total_spent DESC
LIMIT 50;
