WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ca.id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ca ON cc.subject_id = ca.person_id
    LEFT JOIN 
        aka_name an ON ca.person_id = an.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
KeywordedMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        k.keyword
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    km.title,
    km.production_year,
    km.keyword,
    rm.cast_count,
    rm.actor_names
FROM 
    KeywordedMovies km
JOIN 
    RankedMovies rm ON km.movie_id = rm.movie_id
WHERE 
    km.keyword ILIKE '%action%'
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;

