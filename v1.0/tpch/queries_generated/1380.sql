WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        CTE_SupplierTotal.s_total as supplier_total,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    JOIN 
        (SELECT 
            ps.supplied_orderkey, 
            SUM(ps.ps_supplycost * ps.ps_availqty) AS s_total
         FROM 
            partsupp ps 
         JOIN 
            lineitem l ON ps.ps_partkey = l.l_partkey 
         GROUP BY 
            ps.supplied_orderkey) AS CTE_SupplierTotal ON o.o_orderkey = CTE_SupplierTotal.supplied_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_totalprice > 1000.00
),
SupplierDetails AS (
    SELECT 
        DISTINCT s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        RANK() OVER (ORDER BY s.s_acctbal DESC) as acctbal_rank
    FROM 
        supplier s 
    WHERE 
        s.s_acctbal IS NOT NULL
),
NationStats AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acct_bal
    FROM 
        nation n 
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    ns.supplier_count,
    ns.total_acct_bal,
    SUM(ro.o_totalprice) AS total_order_value,
    AVG(ro.supplier_total) AS average_supplier_value
FROM 
    region r 
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    NationStats ns ON n.n_name = ns.n_name
LEFT JOIN 
    RankedOrders ro ON ns.n_name = (
        SELECT 
            n_name 
        FROM 
            nation 
        WHERE 
            n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_name = ro.s_name)
    )
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name, ns.n_name, ns.supplier_count, ns.total_acct_bal
HAVING 
    SUM(ro.o_totalprice) > 5000.00 
    AND COUNT(ns.nation_name) > 1
ORDER BY 
    total_order_value DESC, average_supplier_value ASC;
