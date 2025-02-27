WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
),

MovieStats AS (
    SELECT 
        movie_id,
        title,
        production_year,
        COUNT(DISTINCT actor_name) AS actor_count,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords
    FROM 
        RankedMovies
    GROUP BY 
        movie_id, title, production_year
),

MovieInfo AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        mi.info AS additional_info
    FROM 
        MovieStats m
    JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Summary')
)

SELECT 
    ms.movie_id,
    ms.title,
    ms.production_year,
    ms.actor_count,
    ms.keywords,
    mi.additional_info
FROM 
    MovieStats ms
LEFT JOIN 
    MovieInfo mi ON ms.movie_id = mi.movie_id
ORDER BY 
    ms.production_year DESC, ms.actor_count DESC;
