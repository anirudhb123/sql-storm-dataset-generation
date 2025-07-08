WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.id) DESC) AS year_rank
    FROM 
        aka_title at
        LEFT JOIN cast_info ci ON at.movie_id = ci.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.title, at.production_year
),
SuccessfulMovies AS (
    SELECT 
        rm.title AS movie_title,
        rm.production_year,
        COALESCE(SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS snippet_count
    FROM 
        RankedMovies rm
        LEFT JOIN cast_info ci ON rm.title = (SELECT title FROM aka_title WHERE movie_id = ci.movie_id)
    WHERE 
        rm.year_rank <= 5
    GROUP BY 
        rm.title, rm.production_year
),
TitleInfo AS (
    SELECT 
        mt.movie_id,
        mt.info,
        kt.keyword
    FROM 
        movie_info_idx mt
        JOIN movie_keyword mk ON mt.movie_id = mk.movie_id
        JOIN keyword kt ON mk.keyword_id = kt.id
    WHERE 
        LOWER(mt.info) LIKE '%action%' OR LOWER(mt.info) LIKE '%drama%'
)
SELECT 
    sm.movie_title,
    sm.production_year,
    sm.snippet_count,
    ti.keyword AS movie_keyword,
    at1.title AS related_title,
    CASE 
        WHEN sm.snippet_count > 2 THEN 'Popular'
        WHEN sm.snippet_count BETWEEN 1 AND 2 THEN 'Moderate'
        ELSE 'Unpopular'
    END AS popularity_status
FROM 
    SuccessfulMovies sm
    LEFT JOIN TitleInfo ti ON sm.production_year = (SELECT MAX(production_year) FROM aka_title WHERE id = ti.movie_id)
    LEFT JOIN aka_title at1 ON sm.movie_title <> at1.title AND sm.production_year = at1.production_year
WHERE 
    sm.snippet_count IS NOT NULL
    AND ti.keyword IS NOT NULL
ORDER BY 
    sm.production_year DESC,
    sm.snippet_count DESC
FETCH FIRST 10 ROWS ONLY;
