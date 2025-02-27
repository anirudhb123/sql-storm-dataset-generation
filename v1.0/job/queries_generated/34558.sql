WITH RECURSIVE MovieCTE AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.title) AS year_rank
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),
ActorSubquery AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
KeywordCTE AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mt.movie_id,
    mt.title,
    mt.production_year,
    COALESCE(ak.actor_count, 0) AS total_actors,
    COALESCE(kc.keywords, 'None') AS keywords,
    CASE 
        WHEN mt.year_rank IS NOT NULL THEN 'Ranked Movie'
        ELSE 'Unranked Movie'
    END AS ranking_status
FROM 
    MovieCTE mt
LEFT JOIN 
    ActorSubquery ak ON mt.movie_id = ak.movie_id
LEFT JOIN 
    KeywordCTE kc ON mt.movie_id = kc.movie_id
ORDER BY 
    mt.production_year DESC, 
    mt.title ASC;
