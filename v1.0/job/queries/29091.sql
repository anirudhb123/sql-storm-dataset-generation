WITH MovieDetails AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        a.person_id,
        t.title,
        t.production_year,
        t.kind_id,
        c.nr_order,
        r.role AS person_role,
        p.info AS personal_info,
        k.keyword AS movie_keyword
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        person_info p ON a.person_id = p.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
),
AggregateInfo AS (
    SELECT 
        person_id,
        COUNT(DISTINCT aka_id) AS aka_count,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        MAX(production_year) AS last_movie_year
    FROM 
        MovieDetails
    GROUP BY 
        person_id
)
SELECT 
    a.name AS actor_name,
    ai.aka_count,
    ai.keywords,
    ai.last_movie_year
FROM 
    aka_name a
JOIN 
    AggregateInfo ai ON a.person_id = ai.person_id
WHERE 
    ai.aka_count > 1
ORDER BY 
    ai.last_movie_year DESC;
