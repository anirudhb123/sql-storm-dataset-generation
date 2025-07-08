
WITH RECURSIVE GenreHierarchy AS (
    SELECT k.id AS keyword_id, k.keyword, 1 AS level
    FROM keyword AS k
    WHERE k.keyword LIKE '%Drama%'
    
    UNION ALL
    
    SELECT mk.keyword_id, k.keyword, gh.level + 1
    FROM movie_keyword AS mk
    JOIN keyword AS k ON mk.keyword_id = k.id
    JOIN GenreHierarchy AS gh ON mk.movie_id IN (
        SELECT id
        FROM aka_title
        WHERE title LIKE '%' || k.keyword || '%'
    )
),
PopularMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN ci.nr_order ELSE 0 END) AS average_role_order
    FROM aka_title AS at
    LEFT JOIN cast_info AS ci ON at.id = ci.movie_id
    GROUP BY at.id, at.title, at.production_year
    HAVING COUNT(DISTINCT ci.person_id) > 5
),
MovieProduction AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM movie_companies AS mc
    JOIN company_name AS cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT
    pm.title AS movie_title,
    pm.production_year,
    gh.keyword AS genre,
    pm.cast_count,
    pm.average_role_order,
    COALESCE(mp.companies, 'Unknown') AS production_companies
FROM PopularMovies AS pm
JOIN GenreHierarchy AS gh ON pm.movie_id IN (
    SELECT mk.movie_id
    FROM movie_keyword AS mk
    WHERE mk.keyword_id = gh.keyword_id
)
LEFT JOIN MovieProduction AS mp ON pm.movie_id = mp.movie_id
WHERE pm.production_year >= 2000
ORDER BY pm.cast_count DESC, pm.average_role_order ASC
LIMIT 10;
