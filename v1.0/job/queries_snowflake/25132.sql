
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT ca.person_id) AS actor_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank
    FROM 
        aka_title m
    JOIN 
        cast_info ca ON m.id = ca.movie_id
    JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.actor_count,
        rm.actors,
        rm.keywords
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10
)
SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tm.actor_count,
    tm.actors,
    tm.keywords,
    COALESCE(mi.info, 'No additional info') AS additional_info
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis' LIMIT 1)
ORDER BY 
    tm.actor_count DESC, 
    tm.production_year DESC;
