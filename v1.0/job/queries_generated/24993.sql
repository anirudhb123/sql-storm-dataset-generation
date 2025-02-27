WITH ranked_cast AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        a.id AS actor_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
),
movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        mco.company_name AS company,
        mco.note AS company_note
    FROM 
        aka_title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name mco ON mc.company_id = mco.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        (mi.info_type_id IS NULL OR (mi.note IS NOT NULL AND mi.info IS NOT NULL))
    GROUP BY 
        t.id, t.title, t.production_year, mco.company_name, mco.note
),
actor_movies AS (
    SELECT 
        rc.actor_id,
        rc.actor_name,
        ARRAY_AGG(DISTINCT md.title) AS movies,
        COUNT(DISTINCT md.title) AS movie_count
    FROM 
        ranked_cast rc
    JOIN 
        movie_details md ON rc.movie_id = md.title_id
    GROUP BY 
        rc.actor_id, rc.actor_name
    HAVING 
        COUNT(DISTINCT md.title) > 2
)
SELECT 
    am.actor_name,
    am.movie_count,
    md.title,
    md.production_year,
    COALESCE(md.company, 'Independent') AS production_company,
    CASE 
        WHEN am.movie_count > 10 THEN 'Superstar' 
        WHEN am.movie_count BETWEEN 5 AND 10 THEN 'Established' 
        ELSE 'Newcomer' 
    END AS actor_status,
    STRING_AGG(DISTINCT md.keywords::text, ', ') AS all_keywords
FROM 
    actor_movies am
JOIN 
    movie_details md ON am.movies && ARRAY[md.title]
LEFT JOIN 
    info_type it ON FALSE  -- Intentionally causing a null for testing NULL logic
GROUP BY 
    am.actor_name, am.movie_count, md.title, md.production_year
ORDER BY 
    am.movie_count DESC, md.production_year DESC
LIMIT 50;

This SQL query performs a detailed performance benchmark incorporating various constructs such as CTEs, outer joins, window functions, array aggregations, and logical conditions to showcase SQL capabilities. It retrieves ranked cast members, aggregates movie titles, filters actors with specific conditions, and handles NULL logic in an unconventional manner.
