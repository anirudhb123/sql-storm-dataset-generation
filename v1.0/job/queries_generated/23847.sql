WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM CURRENT_DATE) - t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastInfo AS (
    SELECT 
        c.id AS cast_id,
        c.person_id,
        t.title,
        c.nr_order,
        r.role AS role_name,
        COALESCE(c.note, 'No note') AS note
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        RankedMovies t ON c.movie_id = t.movie_id
    WHERE
        c.nr_order IS NOT NULL
)
SELECT 
    ak.name AS actor_name,
    t.title AS movie_title,
    c.role_name AS character_name,
    t.production_year,
    COALESCE(m.note, 'No additional info') AS movie_note,
    CASE 
        WHEN c.note IS NULL THEN 'No note available' 
        ELSE c.note 
    END AS cast_note,
    CASE 
        WHEN t.production_year < 2000 THEN 'Classic'
        ELSE 'Modern'
    END AS movie_era
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    RankedMovies t ON c.movie_id = t.movie_id
LEFT JOIN 
    movie_info m ON t.movie_id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
WHERE 
    ak.name IS NOT NULL 
    AND t.year_rank <= 3
ORDER BY 
    t.production_year DESC, ak.name;

WITH MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    t.title,
    COALESCE(mk.keywords, 'No keywords') AS movie_keywords
FROM 
    aka_title t
LEFT JOIN 
    MovieKeywords mk ON t.id = mk.movie_id
WHERE 
    t.production_year BETWEEN 1990 AND 2020
ORDER BY 
    t.production_year DESC;

This SQL query retrieves movie data combined with cast information and integrates CTEs for ranking recent films and gathering keywords associated with movies. The first part selects actors, their roles, and associated movie attributes while filtering on recent films. The second part is focused on gathering associated keywords for the relevant titles, ensuring to handle possible NULL values and applying specific logic for categorizing movies based on their production year. Unusual predicates and corner cases have been incorporated to demonstrate complexity while following error-handling best practices.
