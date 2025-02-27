WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        STRING_AGG(DISTINCT na.name, ', ') AS actor_names
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        aka_name na ON ci.person_id = na.person_id
    WHERE 
        a.production_year > 2000
    GROUP BY 
        a.id, a.title, a.production_year, k.keyword
),
MovieInfo AS (
    SELECT 
        m.movie_title, 
        m.production_year, 
        m.movie_keyword,
        COUNT(DISTINCT ci.person_id) AS num_actors
    FROM 
        RankedMovies m
    JOIN 
        complete_cast cc ON m.movie_title = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        m.movie_title, m.production_year, m.movie_keyword
)
SELECT 
    mi.movie_title,
    mi.num_actors,
    mi.movie_keyword
FROM 
    MovieInfo mi
ORDER BY 
    mi.num_actors DESC, mi.production_year DESC
LIMIT 10;
