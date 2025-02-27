WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_price
    FROM orders o
    WHERE o.o_orderdate BETWEEN '1995-01-01' AND '1997-12-31'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(NULLIF(s.s_comment, ''), 'No comment provided') AS comment,
        ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        p.p_retailprice * (1 - ps.ps_supplycost / p.p_retailprice) AS profit_margin,
        RANK() OVER (PARTITION BY p.p_container ORDER BY p.p_retailprice DESC) AS container_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
AllData AS (
    SELECT 
        ro.o_orderkey,
        ro.o_totalprice,
        sd.s_name,
        ps.p_name,
        psi.profit_margin,
        ROW_NUMBER() OVER (PARTITION BY ro.o_orderkey ORDER BY psi.profit_margin DESC) AS best_profit_rank
    FROM RankedOrders ro
    LEFT JOIN SupplierDetails sd ON sd.rn % 10 = ro.o_custkey % 10
    LEFT JOIN PartSupplierInfo psi ON psi.p_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = ro.o_orderkey ORDER BY l.l_linestatus DESC LIMIT 1)
)
SELECT 
    ad.o_orderkey,
    ad.o_totalprice,
    ad.s_name,
    ad.p_name,
    ad.profit_margin
FROM AllData ad
WHERE ad.best_profit_rank = 1
AND ad.o_totalprice > (SELECT AVG(o.o_totalprice) FROM orders o WHERE o.o_orderstatus = 'O')
ORDER BY ad.profit_margin DESC, ad.o_orderkey ASC
LIMIT 100;
