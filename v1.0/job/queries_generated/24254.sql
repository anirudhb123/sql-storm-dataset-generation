WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank_by_year
    FROM 
        aka_title m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature'))
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MetaMovies AS (
    SELECT 
        mov.movie_id,
        mov.title,
        mov.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count,
        CASE 
            WHEN ac.actor_count IS NULL THEN 'NO CAST'
            WHEN ac.actor_count < 3 THEN 'FEW ACTORS'
            ELSE 'MULTIPLE ACTORS'
        END AS actor_category
    FROM 
        RankedMovies mov
    LEFT JOIN 
        ActorCounts ac ON mov.movie_id = ac.movie_id
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalResults AS (
    SELECT 
        mm.title,
        mm.production_year,
        mm.actor_count,
        mm.actor_category,
        COALESCE(ks.keywords_list, 'NO KEYWORDS') AS keywords
    FROM 
        MetaMovies mm
    LEFT JOIN 
        KeywordStats ks ON mm.movie_id = ks.movie_id
    WHERE 
        mm.production_year IS NOT NULL
    AND 
        (mm.actor_count > 0 OR ks.keywords_list IS NOT NULL)
    ORDER BY 
        mm.production_year DESC, 
        mm.actor_count DESC
)
SELECT 
    title,
    production_year,
    actor_count,
    actor_category,
    keywords
FROM 
    FinalResults
WHERE 
    actor_category = 'MULTIPLE ACTORS'
OR 
    production_year = (SELECT MAX(production_year) FROM FinalResults)
OR 
    (actor_count < 3 AND keywords IS NOT NULL)
ORDER BY 
    actor_count DESC, 
    title ASC;
