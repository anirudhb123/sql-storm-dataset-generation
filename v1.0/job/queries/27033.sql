WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title AS mt
    JOIN 
        cast_info AS ci ON mt.id = ci.movie_id
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword AS mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword AS kw ON mk.keyword_id = kw.id
    WHERE 
        mt.production_year >= 2000
        AND mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%movie%')
    GROUP BY 
        mt.id, mt.title, mt.production_year
), MovieRanked AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)

SELECT 
    movie_id,
    movie_title,
    production_year,
    cast_count,
    aka_names,
    keywords
FROM 
    MovieRanked
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC, cast_count DESC;
