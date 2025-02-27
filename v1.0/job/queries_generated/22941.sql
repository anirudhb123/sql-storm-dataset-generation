WITH RECURSIVE RelatedMovies AS (
    SELECT linked_movie_id
    FROM movie_link ml
    WHERE ml.movie_id = (
        SELECT id FROM aka_title WHERE title ILIKE '%Inception%' LIMIT 1
    )
    UNION ALL
    SELECT ml.linked_movie_id
    FROM movie_link ml
    JOIN RelatedMovies rm ON ml.movie_id = rm.linked_movie_id
), 
CastWithRole AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        r.role AS person_role,
        ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY ci.nr_order) AS role_rank
    FROM cast_info ci
    JOIN role_type r ON ci.role_id = r.id
), 
MoviesWithInfo AS (
    SELECT 
        mt.title,
        mt.production_year,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name SEPARATOR ', ') AS production_companies,
        COUNT(DISTINCT mwk.keyword_id) AS keyword_count
    FROM aka_title mt
    LEFT JOIN movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN movie_keyword mwk ON mt.id = mwk.movie_id
    WHERE 
        mt.production_year >= 2000
        AND (
            mt.production_year <= 2020 
            OR mt.title ILIKE '%Avengers%'
        )
    GROUP BY mt.id
)
SELECT 
    mwi.title,
    mwi.production_year,
    COALESCE(mwi.production_companies, 'N/A') AS companies,
    mwi.keyword_count,
    cw.person_role,
    COUNT(DISTINCT rc.linked_movie_id) AS related_movie_count
FROM MoviesWithInfo mwi
LEFT JOIN CastWithRole cw ON 
    cw.movie_id IN (SELECT DISTINCT rm.linked_movie_id FROM RelatedMovies rm WHERE rm.linked_movie_id = mwi.title)
LEFT JOIN movie_link rc ON mwi.title = rc.movie_id
LEFT JOIN RelatedMovies rm ON rm.linked_movie_id = rc.linked_movie_id
WHERE 
    cw.role_rank = 1
GROUP BY 
    mwi.title, mwi.production_year, mwi.production_companies, mwi.keyword_count, cw.person_role
HAVING 
    COUNT(DISTINCT rc.linked_movie_id) > 0
ORDER BY 
    mwi.production_year DESC, mwi.keyword_count DESC;
