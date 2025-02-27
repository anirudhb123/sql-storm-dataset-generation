WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movie_count AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        ranked_movies rm ON c.movie_id = rm.movie_id
    WHERE 
        c.nr_order IS NOT NULL
    GROUP BY 
        c.person_id
),
top_actors AS (
    SELECT 
        a.person_id,
        a.movie_count,
        a.rank,
        RANK() OVER (ORDER BY a.movie_count DESC) AS rank
    FROM 
        actor_movie_count a
    WHERE 
        a.movie_count > 5
),
actor_names AS (
    SELECT 
        an.id AS actor_id,
        an.name
    FROM 
        aka_name an
    JOIN 
        top_actors ta ON an.person_id = ta.person_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        COALESCE(cn.name, 'Unknown') AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(an.name, 'No Actor') AS actor_name,
    ci.company_name,
    ci.company_type,
    COUNT(DISTINCT ci.company_name) OVER (PARTITION BY rm.movie_id) AS total_companies,
    SUM(CASE WHEN ci.company_type IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY rm.movie_id) AS filled_company_types
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_info c ON rm.movie_id = c.movie_id
LEFT JOIN 
    actor_names an ON c.person_id = an.actor_id
LEFT JOIN 
    company_info ci ON rm.movie_id = ci.movie_id
WHERE 
    rm.rn <= 10
ORDER BY 
    rm.production_year DESC, 
    COUNT(DISTINCT ci.company_name) DESC;
