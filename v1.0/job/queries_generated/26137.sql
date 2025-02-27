WITH popular_titles AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(mc.movie_id) AS company_count,
        ARRAY_AGG(DISTINCT c.kind) AS company_types
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, 
        t.production_year
    HAVING 
        COUNT(mc.movie_id) > 3
),
frequent_cast AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(ci.movie_id) > 5
),
keywords_used AS (
    SELECT 
        k.keyword,
        COUNT(mk.movie_id) AS usage_count
    FROM 
        keyword k
    JOIN 
        movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY 
        k.keyword
    ORDER BY 
        usage_count DESC
    LIMIT 10
)
SELECT 
    pt.title,
    pt.production_year,
    pt.company_count,
    ARRAY_TO_STRING(pt.company_types, ', ') AS company_types,
    fc.actor_name,
    fc.movie_count,
    ku.keyword,
    ku.usage_count
FROM 
    popular_titles pt
JOIN 
    frequent_cast fc ON pt.company_count < fc.movie_count
CROSS JOIN 
    keywords_used ku
ORDER BY 
    pt.production_year DESC,
    pt.title;
