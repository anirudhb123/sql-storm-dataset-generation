
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
),
EligibleParts AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size BETWEEN 1 AND 20
    GROUP BY 
        p.p_partkey
    HAVING 
        SUM(ps.ps_availqty) > 50
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        c.c_name, 
        RANK() OVER (ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate < DATE('1998-10-01') - INTERVAL '30 days'
),
SupplierDetails AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        ep.total_available,
        cp.o_orderkey,
        CASE 
            WHEN cp.o_totalprice > 10000 THEN 'High Value'
            ELSE 'Regular'
        END AS order_class
    FROM 
        RankedSuppliers rs
    LEFT JOIN 
        EligibleParts ep ON rs.s_suppkey = ep.p_partkey
    LEFT JOIN 
        CustomerOrders cp ON rs.s_suppkey = cp.o_orderkey
    WHERE 
        ep.total_available IS NOT NULL 
        OR cp.order_rank IS NOT NULL
)
SELECT 
    sd.s_suppkey,
    sd.s_name,
    COALESCE(sd.total_available, 0) AS available_quantity,
    COUNT(cp.o_orderkey) AS total_orders,
    LISTAGG(DISTINCT sd.order_class, ', ') WITHIN GROUP (ORDER BY sd.order_class) AS classifications,
    SUM(cp.o_totalprice) AS total_revenue
FROM 
    SupplierDetails sd
LEFT JOIN 
    CustomerOrders cp ON sd.o_orderkey = cp.o_orderkey
GROUP BY 
    sd.s_suppkey, 
    sd.s_name, 
    sd.total_available
HAVING 
    COUNT(cp.o_orderkey) > 0
ORDER BY 
    total_revenue DESC NULLS LAST;
