WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(month, -6, GETDATE())
    AND 
        o.o_totalprice > 100.00
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name
    FROM 
        CustomerDetails c
    WHERE 
        c.total_spent > 10000.00
),
PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        ps.total_available,
        (p.p_retailprice * ps.total_available) AS total_value
    FROM 
        part p
    LEFT JOIN 
        SupplierParts ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    o.o_orderkey,
    o.o_orderstatus,
    p.p_name,
    COALESCE(s.s_name, 'N/A') AS supplier_name,
    COALESCE(b.total_value, 0) AS total_value,
    c.c_name,
    RANK() OVER (ORDER BY o.o_totalprice DESC) AS price_rank
FROM 
    RankedOrders o
LEFT JOIN 
    PartSupplierDetails b ON o.o_orderkey = (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = b.supplier_name ORDER BY l.l_extendedprice DESC FETCH FIRST 1 ROW ONLY)
LEFT JOIN 
    HighValueCustomers c ON o.o_orderkey = (SELECT o.o_orderkey FROM orders o JOIN lineitem l ON o.o_orderkey = l.l_orderkey WHERE l.l_orderkey = o.o_orderkey AND c.c_custkey = o.o_custkey)
WHERE 
    o.order_rank <= 10
ORDER BY 
    price_rank, total_value DESC;
