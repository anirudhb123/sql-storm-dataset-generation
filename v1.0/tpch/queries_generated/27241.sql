WITH SupplierInfo AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_address, 
           n.n_name AS nation_name, 
           s.s_acctbal, 
           s.s_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
PartDetails AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_brand, 
           p.p_container, 
           p.p_retailprice, 
           p.p_comment,
           ps.ps_availqty,
           ps.ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, 
           c.c_name, 
           o.o_orderkey, 
           o.o_orderdate, 
           o.o_totalprice, 
           o.o_orderstatus
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F' 
      AND c.c_acctbal > 1000.00
)
SELECT si.s_suppkey, 
       si.s_name, 
       si.nation_name, 
       pd.p_name, 
       pd.p_brand, 
       pd.p_retailprice, 
       co.o_orderkey, 
       co.o_totalprice
FROM SupplierInfo si
JOIN PartDetails pd ON pd.ps_supplycost > 20.00
JOIN CustomerOrders co ON si.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps 
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
    WHERE l.l_quantity > 5
)
ORDER BY si.nation_name, pd.p_retailprice DESC, co.o_orderdate DESC;
