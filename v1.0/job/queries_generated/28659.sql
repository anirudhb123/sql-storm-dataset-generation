WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        k.keyword, 
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
MovieCast AS (
    SELECT 
        t.id AS movie_id, 
        a.name AS actor_name, 
        a.id AS actor_id, 
        c.nr_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    JOIN 
        aka_title t ON t.id = c.movie_id
),
PopularMovies AS (
    SELECT 
        movie_id,
        STRING_AGG(DISTINCT actor_name, ', ') AS cast,
        COUNT(DISTINCT keyword) AS keyword_count
    FROM 
        MovieCast
    GROUP BY 
        movie_id
),
FinalResults AS (
    SELECT 
        rm.title,
        rm.production_year,
        pm.cast,
        pm.keyword_count,
        CASE 
            WHEN pm.keyword_count > 5 THEN 'Highly Tagged'
            WHEN pm.keyword_count BETWEEN 3 AND 5 THEN 'Moderately Tagged'
            ELSE 'Poorly Tagged'
        END AS tag_status
    FROM 
        RankedMovies rm
    JOIN 
        PopularMovies pm ON rm.id = pm.movie_id
    WHERE 
        rm.keyword_rank = 1
)
SELECT 
    title, 
    production_year, 
    cast, 
    keyword_count, 
    tag_status
FROM 
    FinalResults
ORDER BY 
    production_year DESC, 
    keyword_count DESC;
