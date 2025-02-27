
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        RANK() OVER (ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS actor_rank
    FROM 
        aka_title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
MovieInfo AS (
    SELECT 
        ri.movie_id,
        ri.movie_title,
        ri.production_year,
        ri.cast_count,
        ri.actor_names,
        ARRAY_AGG(DISTINCT mi.info) AS additional_info
    FROM 
        RankedMovies ri
    LEFT JOIN 
        movie_info mi ON ri.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%box office%')
    GROUP BY 
        ri.movie_id, ri.movie_title, ri.production_year, ri.cast_count, ri.actor_names
)
SELECT 
    m.movie_id,
    m.movie_title,
    m.production_year,
    m.cast_count,
    m.actor_names,
    COALESCE(m.additional_info[1], 'No box office info') AS box_office_info
FROM 
    MovieInfo m
WHERE 
    m.cast_count > 10
ORDER BY 
    m.production_year DESC, 
    m.cast_count DESC
LIMIT 50;
