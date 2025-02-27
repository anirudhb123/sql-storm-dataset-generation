
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors_list
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
), MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), FinalReport AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.actors_list,
        mk.keywords_list
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    ORDER BY 
        rm.production_year DESC, rm.cast_count DESC
)
SELECT 
    movie_id,
    title,
    production_year,
    cast_count,
    actors_list,
    keywords_list
FROM 
    FinalReport
LIMIT 100;
