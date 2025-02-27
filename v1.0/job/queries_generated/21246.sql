WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        AVG(mi.rating) FILTER (WHERE mi.rating IS NOT NULL) AS avg_rating,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_with_cast
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'average rating')
    GROUP BY 
        t.id
),

FilteredActors AS (
    SELECT 
        ak.name AS actor_name,
        ct.kind AS role_type,
        COUNT(ci.movie_id) AS movies_played
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        role_type ct ON ci.role_id = ct.id
    WHERE 
        ak.md5sum IS NOT NULL
    GROUP BY 
        ak.name, ct.kind
    HAVING 
        COUNT(ci.movie_id) > 5
),

MoviesWithKeywords AS (
    SELECT 
        m.title,
        k.keyword
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword IS NOT NULL
)

SELECT 
    rm.title_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(rm.avg_rating, 'N/A') AS average_rating,
    fa.actor_name,
    fa.role_type,
    mwk.keyword
FROM 
    RankedMovies rm
LEFT JOIN 
    FilteredActors fa ON fa.movies_played = rm.cast_count
LEFT JOIN 
    MoviesWithKeywords mwk ON mwk.title = rm.title
WHERE 
    (rm.rank_with_cast = 1 OR rm.cast_count < 10)
    AND rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC, fa.actor_name;
