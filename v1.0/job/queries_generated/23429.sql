WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),

ActorMovies AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
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

MoviesWithDetails AS (
    SELECT 
        r.title_id,
        r.title,
        r.production_year,
        am.actor_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        CASE 
            WHEN r.rank_by_year IS NULL THEN 'Not Ranked'
            ELSE 'Ranked'
        END AS rank_status
    FROM 
        RankedTitles r
    LEFT JOIN 
        ActorMovies am ON r.title_id = am.movie_id
    LEFT JOIN 
        MovieKeywords mk ON r.title_id = mk.movie_id
)

SELECT 
    m.title,
    m.production_year,
    m.actor_count,
    m.keywords,
    m.rank_status,
    CONCAT('Title: ', m.title, ', Year: ', m.production_year, ', Actors: ', COALESCE(m.actor_count::text, '0'), ', Keywords: ', m.keywords) AS detailed_info
FROM 
    MoviesWithDetails m
WHERE 
    m.production_year >= 2000
    AND (m.keywords LIKE '%Action%' OR m.actor_count > 5)
ORDER BY 
    m.production_year DESC, 
    m.actor_count DESC
FETCH FIRST 50 ROWS ONLY;
