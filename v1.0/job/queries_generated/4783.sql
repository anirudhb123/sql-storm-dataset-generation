WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.id AS movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
MovieActors AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT an.name, ', ') AS actors
    FROM 
        RankedMovies m
    INNER JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    INNER JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        m.rank <= 10
    GROUP BY 
        m.movie_id
),
HighRatedMovies AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT ke.id) AS keyword_count
    FROM 
        movie_info m
    INNER JOIN 
        movie_keyword ke ON m.movie_id = ke.movie_id
    WHERE 
        m.info_type_id IN (SELECT id FROM info_type WHERE info = 'Rating')
    GROUP BY 
        m.movie_id
    HAVING 
        COUNT(DISTINCT ke.id) > 5
)
SELECT 
    rm.title,
    rm.production_year,
    ma.actors,
    COALESCE(hm.keyword_count, 0) AS keyword_count
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieActors ma ON rm.movie_id = ma.movie_id
LEFT JOIN 
    HighRatedMovies hm ON rm.movie_id = hm.movie_id
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, rm.title;
