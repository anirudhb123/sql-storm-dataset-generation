
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(aka.name, ', ') AS aliases
    FROM 
        aka_title AS t 
    JOIN 
        cast_info AS c ON t.id = c.movie_id
    JOIN 
        aka_name AS aka ON c.person_id = aka.person_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
    HAVING 
        COUNT(c.person_id) > 5
), 
PopularKeywords AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
    HAVING 
        COUNT(mk.keyword_id) >= 3
), 
FinalSelection AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        pk.keyword_count,
        rm.aliases
    FROM 
        RankedMovies AS rm
    JOIN 
        PopularKeywords AS pk ON rm.movie_id = pk.movie_id
    WHERE 
        rm.production_year BETWEEN 2000 AND 2020
)
SELECT 
    title,
    production_year,
    cast_count,
    keyword_count,
    aliases
FROM 
    FinalSelection
ORDER BY 
    production_year DESC, cast_count DESC;
