WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey 
    WHERE 
        o.o_orderdate >= '2022-01-01' 
        AND o.o_orderdate < '2023-01-01'
), SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), NationBalance AS (
    SELECT 
        n.n_nationkey,
        SUM(s.s_acctbal) AS total_balance
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_nationkey
), FinalResults AS (
    SELECT 
        o.order_rank,
        o.o_orderkey,
        o.o_totalprice,
        n.n_name,
        ISNULL(pb.total_available, 0) AS total_available_parts,
        ISNULL(nb.total_balance, 0) AS supplier_balance
    FROM 
        RankedOrders o
    LEFT JOIN 
        SupplierParts pb ON o.o_orderkey = pb.ps_partkey
    LEFT JOIN 
        NationBalance nb ON o.c_nationkey = nb.n_nationkey
    WHERE 
        pb.total_available > 5 OR nb.total_balance > 10000
)
SELECT 
    f.o_orderkey,
    f.o_totalprice,
    f.n_name,
    f.total_available_parts,
    f.supplier_balance
FROM 
    FinalResults f
WHERE 
    f.order_rank <= 10
ORDER BY 
    f.o_totalprice DESC;
