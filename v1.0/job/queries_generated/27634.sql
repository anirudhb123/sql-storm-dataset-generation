WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000 AND 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
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
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        ac.actor_count
    FROM 
        RankedMovies m
    LEFT JOIN 
        ActorCounts ac ON m.movie_id = ac.movie_id
    WHERE 
        m.rank <= 10
),
MoviesWithKeywords AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.actor_count,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        MovieDetails md
    LEFT JOIN 
        movie_keyword mk ON md.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        md.movie_id, md.title, md.production_year, md.actor_count
)
SELECT 
    mwk.movie_id,
    mwk.title,
    mwk.production_year,
    mwk.actor_count,
    mwk.keywords,
    COALESCE(ci.note, 'No additional info') AS cast_note
FROM 
    MoviesWithKeywords mwk
LEFT JOIN 
    complete_cast ci ON mwk.movie_id = ci.movie_id
ORDER BY 
    mwk.production_year DESC, mwk.actor_count DESC;
