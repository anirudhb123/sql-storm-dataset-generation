WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS all_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
person_roles AS (
    SELECT 
        ci.movie_id,
        r.role AS role_name,
        COUNT(ci.person_id) AS total_people
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, r.role
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(mk.all_keywords, 'No keywords') AS keywords,
    COALESCE(t.role_name, 'No roles') AS role_name,
    COALESCE(t.total_people, 0) AS number_of_people,
    CASE 
        WHEN rm.rank <= 5 THEN 'Top Film'
        WHEN rm.rank <= 10 THEN 'Mid Tier Film'
        ELSE 'Independent'
    END AS film_category,
    CASE
        WHEN mk.all_keywords IS NOT NULL OR mk.all_keywords <> '' THEN 'Has Keywords'
        ELSE 'No Keyword'
    END AS keyword_status
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    person_roles t ON rm.movie_id = t.movie_id
WHERE 
    rm.production_year BETWEEN 1990 AND 2023
    AND (t.total_people IS NULL OR t.total_people > 0) 
    AND (rm.title NOT LIKE '%unreleased%' OR rm.title IS NULL)
ORDER BY 
    rm.production_year DESC, rm.title ASC;
