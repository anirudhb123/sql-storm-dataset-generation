
WITH RECURSIVE movie_appearances AS (
    SELECT 
        ci.person_id,
        ct.kind AS role,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY t.production_year DESC) AS appearance_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    WHERE 
        ct.kind IS NOT NULL
),
qualified_actors AS (
    SELECT 
        ma.person_id,
        a.name,
        COUNT(*) AS total_appearances,
        MIN(ma.production_year) AS first_appearance,
        MAX(ma.production_year) AS last_appearance
    FROM 
        movie_appearances ma
    JOIN 
        aka_name a ON ma.person_id = a.person_id
    GROUP BY 
        ma.person_id, a.name
    HAVING 
        COUNT(*) > 5 AND 
        MAX(ma.production_year) <= EXTRACT(YEAR FROM DATE '2024-10-01') - 5
),
notable_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id 
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title
    HAVING 
        COUNT(mk.keyword_id) >= 3
)
SELECT 
    qa.name,
    qa.total_appearances,
    qa.first_appearance,
    qa.last_appearance,
    nm.title AS notable_movie,
    nm.keyword_count
FROM 
    qualified_actors qa
CROSS JOIN 
    notable_movies nm
WHERE 
    nm.keyword_count > (
        SELECT 
            AVG(keyword_count) 
        FROM 
            notable_movies
    )
ORDER BY 
    qa.total_appearances DESC,
    qa.last_appearance DESC
LIMIT 10
OFFSET 5;
