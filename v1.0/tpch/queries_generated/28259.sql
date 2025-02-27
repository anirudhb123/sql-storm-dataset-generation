WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, n.n_name AS nation_name, r.r_name AS region_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_container, 
           (SELECT SUM(ps.ps_supplycost * ps.ps_availqty) 
            FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey) AS total_supply_cost
    FROM part p
),
CustomerOrders AS (
    SELECT o.o_orderkey, c.c_custkey, c.c_name, o.o_totalprice, o.o_orderdate
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
Benchmark AS (
    SELECT sd.s_name, pd.p_name, co.c_name, co.o_totalprice,
           CONCAT('Supplier: ', sd.s_name, ', Part: ', pd.p_name, 
                  ', Customer: ', co.c_name, ', Total Price: ', 
                  CAST(co.o_totalprice AS VARCHAR), 
                  ', Total Supply Cost: ', CAST(pd.total_supply_cost AS VARCHAR)) AS benchmark_info
    FROM SupplierDetails sd
    JOIN PartDetails pd ON pd.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sd.s_suppkey)
    JOIN CustomerOrders co ON co.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = pd.p_partkey)
)
SELECT benchmark_info FROM Benchmark WHERE total_supply_cost > 1000 ORDER BY s_name, p_name;
