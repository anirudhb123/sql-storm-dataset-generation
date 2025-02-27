WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
),
CombinedData AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.c_name,
        ro.total_revenue,
        sd.s_name AS supplier_name,
        sd.p_name AS part_name,
        sd.p_retailprice,
        sd.s_acctbal
    FROM 
        RankedOrders ro
    LEFT JOIN 
        SupplierDetails sd ON ro.o_orderkey = sd.ps_partkey
    WHERE 
        sd.supplier_rank = 1
)
SELECT 
    cd.o_orderkey,
    cd.o_orderdate,
    cd.c_name,
    COALESCE(cd.total_revenue, 0) AS total_revenue,
    cd.supplier_name,
    cd.part_name,
    (CASE 
        WHEN cd.p_retailprice IS NULL THEN 'NA' 
        ELSE FORMAT(cd.p_retailprice, 'C')
    END) AS formatted_retailprice,
    (CASE 
        WHEN cd.s_acctbal IS NULL THEN 'NO BALANCE' 
        ELSE CAST(cd.s_acctbal AS VARCHAR)
    END) AS supplier_account_balance
FROM 
    CombinedData cd
WHERE 
    cd.total_revenue > (SELECT AVG(total_revenue) FROM RankedOrders)
ORDER BY 
    cd.o_orderdate DESC, total_revenue DESC;
