WITH RankedMovies AS (
    SELECT 
        t.id as title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) as rank_by_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieStats AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(c.person_id) AS total_cast,
        SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS credited_cast
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    LEFT JOIN role_type ci ON c.role_id = ci.id
    GROUP BY c.movie_id, a.name
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE 
        mk.keyword_id IS NOT NULL
    GROUP BY m.id, m.title
),
FinalResult AS (
    SELECT 
        r.title_id,
        r.title,
        r.production_year,
        ams.actor_name,
        ams.total_cast,
        ams.credited_cast,
        mwk.keywords,
        COALESCE((ams.total_cast - ams.credited_cast), 0) AS uncredited_cast,
        CASE 
            WHEN ams.credited_cast = 0 THEN 'No credited roles'
            ELSE CAST(ams.credited_cast AS text) || ' credited roles'
        END AS role_message
    FROM 
        RankedMovies r
    LEFT JOIN ActorMovieStats ams ON r.title_id = ams.movie_id
    LEFT JOIN MoviesWithKeywords mwk ON r.title_id = mwk.movie_id
)
SELECT 
    title,
    production_year,
    actor_name,
    total_cast,
    credited_cast,
    uncredited_cast,
    keywords,
    role_message
FROM 
    FinalResult 
WHERE 
    production_year BETWEEN 2000 AND 2023
ORDER BY 
    production_year DESC,
    actor_name;
