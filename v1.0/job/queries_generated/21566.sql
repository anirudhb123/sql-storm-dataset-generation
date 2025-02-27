WITH RECURSIVE FilmTopCo AS (
    SELECT m.id AS movie_id, c.name AS company_name, c.country_code,
           ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY ct.kind) AS rn,
           DENSE_RANK() OVER (ORDER BY m.production_year DESC) AS year_rank
    FROM aka_title m
    JOIN movie_companies mc ON m.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE c.country_code IS NOT NULL
), CastDetails AS (
    SELECT a.id AS cast_id, a.person_id, b.title AS movie_title, 
           COALESCE(a.nr_order, 999) AS order_num,
           ROW_NUMBER() OVER (PARTITION BY a.movie_id ORDER BY COALESCE(a.nr_order, 999)) AS role_num
    FROM cast_info a
    LEFT JOIN aka_title b ON a.movie_id = b.id
), PersonInfo AS (
    SELECT p.id AS person_id, p.name AS person_name,
           COALESCE(pi.info, '(No Info)') AS p_info,
           ROW_NUMBER() OVER (PARTITION BY p.id ORDER BY COALESCE(pi.info_type_id, 999)) AS info_rank
    FROM name p
    LEFT JOIN person_info pi ON p.imdb_id = pi.person_id
), FilmCompany AS (
    SELECT DISTINCT f.movie_id, c.company_name, MAX(c.country_code) AS country_code
    FROM FilmTopCo f
    JOIN movie_companies mc ON f.movie_id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    GROUP BY f.movie_id, c.company_name
)
SELECT DISTINCT 
    ft.movie_id, 
    ft.company_name, 
    ft.country_code, 
    cd.movie_title, 
    pd.person_name, 
    pd.p_info,
    cd.order_num,
    cf.kind AS cast_kind,
    CASE 
        WHEN pd.info_rank IS NULL THEN 'Info Missing' 
        ELSE 'Info Present' 
    END AS info_status
FROM FilmTopCo ft
FULL JOIN CastDetails cd ON ft.movie_id = cd.movie_id
LEFT JOIN PersonInfo pd ON cd.person_id = pd.person_id
LEFT JOIN comp_cast_type cf ON cd.role_id = cf.id
WHERE ft.year_rank <= 5
  AND (cd.order_num < 10 OR pd.p_info IS NOT NULL)
ORDER BY ft.movie_id, cd.order_num DESC, pd.info_rank;
