WITH movie_title AS (
    SELECT 
        t.id AS title_id, 
        t.title,
        t.production_year,
        k.keyword
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
), 
actor_details AS (
    SELECT 
        a.person_id, 
        a.name, 
        COUNT(c.movie_id) AS movie_count, 
        RANK() OVER (ORDER BY COUNT(c.movie_id) DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id, a.name
), 
company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
)
SELECT 
    mt.title, 
    mt.production_year, 
    ad.name AS actor_name,
    COALESCE(ci.companies, 'No Companies') AS companies,
    ad.movie_count
FROM 
    movie_title mt
LEFT JOIN 
    cast_info ci ON mt.title_id = ci.movie_id
LEFT JOIN 
    actor_details ad ON ci.person_id = ad.person_id
LEFT JOIN 
    company_info ci ON mt.title_id = ci.movie_id
WHERE 
    ad.rank <= 10
ORDER BY 
    mt.production_year DESC, 
    ad.movie_count DESC;
