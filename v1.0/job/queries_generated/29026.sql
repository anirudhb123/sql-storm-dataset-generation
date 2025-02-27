WITH RecursiveTitleCTE AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ak.name AS alias_name,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.role_id::text, ', ') AS role_ids,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title AS m
    LEFT JOIN aka_name AS ak ON ak.person_id IN (
        SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = m.id
    )
    LEFT JOIN movie_keyword AS mk ON mk.movie_id = m.id
    LEFT JOIN keyword AS k ON k.id = mk.keyword_id
    LEFT JOIN cast_info AS ci ON ci.movie_id = m.id
    GROUP BY 
        m.id, m.title, m.production_year, ak.name
),

FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        alias_name, 
        keywords,
        CAST(cast_count AS INTEGER) AS total_cast
    FROM 
        RecursiveTitleCTE
    WHERE 
        production_year BETWEEN 2000 AND 2020 
        AND total_cast > 1
)

SELECT 
    title, 
    production_year, 
    alias_name, 
    keywords, 
    total_cast 
FROM 
    FilteredMovies 
ORDER BY 
    production_year DESC, 
    total_cast DESC
LIMIT 10;

This query constructs a recursive Common Table Expression (CTE) that aggregates movie details, including names and keywords, while filtering for movies released between 2000 and 2020 with more than one cast member. The final selection retrieves the most relevant entries, sorted by year and cast count.
