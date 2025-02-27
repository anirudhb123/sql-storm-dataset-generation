WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        (t.production_year IS NOT NULL AND t.production_year >= 2000)
        OR (t.production_year IS NULL AND t.title IS NOT NULL)
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
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MoviesWithActorCounts AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCounts ac ON rm.movie_id = ac.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
)
SELECT 
    m.title,
    m.production_year,
    m.actor_count,
    m.keywords,
    CASE 
        WHEN m.actor_count > 10 THEN 'Ensemble Cast'
        WHEN m.actor_count BETWEEN 5 AND 10 THEN 'Moderate Cast'
        ELSE 'Minimal Cast'
    END AS cast_type,
    (SELECT COUNT(*)
     FROM complete_cast cc
     WHERE cc.movie_id = m.movie_id) AS complete_cast_count,
    (SELECT COUNT(*)
     FROM movie_info mi
     WHERE mi.movie_id = m.movie_id
     AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Brief')) AS brief_info_count,
    (SELECT STRING_AGG(DISTINCT cn.name, ', ')
     FROM movie_companies mc
     JOIN company_name cn ON mc.company_id = cn.id
     WHERE mc.movie_id = m.movie_id) AS production_companies
FROM 
    MoviesWithActorCounts m
WHERE 
    m.year_rank <= 5
    AND (m.production_year IS NOT NULL OR m.actor_count > 0)
ORDER BY 
    m.production_year DESC, m.actor_count DESC;
