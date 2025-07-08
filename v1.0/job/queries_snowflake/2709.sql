
WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.id) AS year_rank
    FROM title
    WHERE title.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        movie_id,
        LISTAGG(keyword.keyword, ', ') WITHIN GROUP (ORDER BY keyword.keyword) AS keywords
    FROM movie_keyword
    JOIN keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY movie_id
),
CompanyCounts AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT company_id) AS company_count
    FROM movie_companies
    GROUP BY movie_id
),
ActorInfo AS (
    SELECT 
        cast_info.movie_id,
        LISTAGG(DISTINCT aka_name.name, ', ') WITHIN GROUP (ORDER BY aka_name.name) AS actor_names
    FROM cast_info
    JOIN aka_name ON cast_info.person_id = aka_name.person_id
    GROUP BY cast_info.movie_id
)
SELECT 
    RM.movie_id,
    RM.title,
    RM.production_year,
    COALESCE(K.keywords, 'No keywords') AS keywords,
    COALESCE(AI.actor_names, 'No actors') AS actor_names,
    COALESCE(CC.company_count, 0) AS company_count,
    CASE WHEN RM.year_rank <= 5 THEN 'Top 5 of Year' ELSE 'Below Top 5' END AS ranking_status
FROM RankedMovies RM
LEFT JOIN MovieKeywords K ON RM.movie_id = K.movie_id
LEFT JOIN ActorInfo AI ON RM.movie_id = AI.movie_id
LEFT JOIN CompanyCounts CC ON RM.movie_id = CC.movie_id
WHERE RM.production_year > 2000
ORDER BY RM.production_year DESC, RM.movie_id;
