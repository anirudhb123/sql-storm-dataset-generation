WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        array_agg(ca.name) AS cast_names,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mk.keyword) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ca ON ci.person_id = ca.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRankedMovies AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year, 
        cast_names 
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tr.movie_title,
    tr.production_year,
    tr.cast_names,
    COUNT(mn.id) AS name_variations,
    STRING_AGG(DISTINCT mn.name, ', ') AS unique_names
FROM 
    TopRankedMovies tr
JOIN 
    name mn ON tr.cast_names::text LIKE '%' || mn.name || '%'
GROUP BY 
    tr.movie_title, tr.production_year, tr.cast_names
ORDER BY 
    tr.production_year DESC, COUNT(mn.id) DESC;

This query benchmarks string processing by finding the top 5 movies from each production year based on cast keyword associations and counts how many name variations exist in the `name` table that are associated with the cast of those top movies. It utilizes common table expressions (CTEs) to structure the query logically, aiding in readability and performance benchmarking on string operations.
