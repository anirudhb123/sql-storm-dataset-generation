WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS starring_actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS movie_keywords
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRatedMovies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        rm.starring_actors,
        rm.movie_keywords,
        mi.info AS rating
    FROM 
        RankedMovies rm
    JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
)
SELECT 
    t.movie_title,
    t.production_year,
    t.cast_count,
    t.starring_actors,
    t.movie_keywords,
    COALESCE(t.rating, 'N/A') AS rating
FROM 
    TopRatedMovies t
ORDER BY 
    t.production_year DESC, 
    t.cast_count DESC
LIMIT 10;
