WITH RankedCast AS (
    SELECT 
        ci.movie_id,
        cn.name AS character_name,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        char_name cn ON cn.imdb_id = ak.person_id
),
RecentMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.id) AS company_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    WHERE 
        mt.production_year >= (SELECT MAX(production_year) - 10 FROM aka_title) 
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_total
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
FilteredCast AS (
    SELECT 
        rc.movie_id,
        rc.actor_name,
        rc.character_name,
        rc.role_rank
    FROM 
        RankedCast rc
    WHERE 
        rc.role_rank <= 3
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(fc.actor_name, 'Unknown') AS main_actor,
    COALESCE(fc.character_name, 'Unknown Character') AS character_played,
    COALESCE(kc.keyword_total, 0) AS total_keywords,
    rm.company_count
FROM 
    RecentMovies rm
LEFT JOIN 
    FilteredCast fc ON rm.movie_id = fc.movie_id
LEFT JOIN 
    KeywordCount kc ON rm.movie_id = kc.movie_id
WHERE 
    rm.company_count > 0
ORDER BY 
    rm.production_year DESC,
    rm.title;