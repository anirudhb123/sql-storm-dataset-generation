WITH TotalSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
TopProducts AS (
    SELECT 
        p_partkey,
        p_name,
        total_revenue
    FROM 
        TotalSales
    WHERE 
        sales_rank <= 10
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_totalprice > 500
),
RegionSupplier AS (
    SELECT 
        r.r_name,
        s.s_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name, s.s_name
)
SELECT 
    T.p_name,
    T.total_revenue,
    S.s_name,
    C.o_orderkey,
    C.o_totalprice
FROM 
    TopProducts T
JOIN 
    SupplierDetails S ON T.p_partkey = S.s_suppkey
JOIN 
    CustomerOrders C ON C.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_acctbal > 1000)
WHERE 
    S.total_supply_cost IS NOT NULL
ORDER BY 
    T.total_revenue DESC, C.o_totalprice DESC;
