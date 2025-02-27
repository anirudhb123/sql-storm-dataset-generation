WITH actor_movie_summary AS (
    SELECT 
        ak.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords,
        GROUP_CONCAT(DISTINCT ct.kind ORDER BY ct.kind SEPARATOR ', ') AS company_types,
        COUNT(DISTINCT c.id) AS total_roles
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        ak.name, t.title, t.production_year
),

actor_summary AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_title) AS movie_count,
        SUM(total_roles) AS total_roles,
        COUNT(DISTINCT production_year) AS unique_years_active
    FROM 
        actor_movie_summary
    GROUP BY 
        actor_name
)

SELECT 
    actor_name,
    movie_count,
    total_roles,
    unique_years_active,
    CASE 
        WHEN unique_years_active > 10 THEN 'Veteran'
        WHEN unique_years_active BETWEEN 5 AND 10 THEN 'Experienced'
        ELSE 'Novice'
    END AS experience_level
FROM 
    actor_summary
ORDER BY 
    total_roles DESC, movie_count DESC;
