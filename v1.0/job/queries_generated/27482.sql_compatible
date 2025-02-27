
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    LEFT JOIN 
        cast_info AS c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name AS ak ON c.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
), MovieInfo AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.cast_count,
        m.aka_names,
        COUNT(DISTINCT mi.id) AS info_count,
        COUNT(DISTINCT mk.id) AS keyword_count
    FROM 
        RankedMovies AS m
    LEFT JOIN 
        movie_info AS mi ON m.movie_id = mi.movie_id
    LEFT JOIN 
        movie_keyword AS mk ON m.movie_id = mk.movie_id
    GROUP BY 
        m.movie_id, m.title, m.production_year, m.cast_count, m.aka_names
)

SELECT 
    mi.title,
    mi.production_year,
    mi.cast_count,
    mi.info_count,
    mi.keyword_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    MovieInfo AS mi
LEFT JOIN 
    movie_keyword AS mk ON mi.movie_id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
GROUP BY 
    mi.title, mi.production_year, mi.cast_count, mi.info_count, mi.keyword_count
ORDER BY 
    mi.production_year DESC, mi.cast_count DESC, mi.title
LIMIT 10;
