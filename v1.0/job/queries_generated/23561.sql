WITH RecursiveMovieSequences AS (
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title, 
        CAST(m.production_year AS text) AS production_year,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY cm.movie_id) AS sequence_number
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code IS NOT NULL AND cn.country_code <> ''
),
ActorInfo AS (
    SELECT 
        a.name AS actor_name, 
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        SUM(CASE WHEN ci.note LIKE '%lead%' THEN 1 ELSE 0 END) AS lead_roles,
        AVG(CASE 
                WHEN ci.nr_order IS NOT NULL AND ci.nr_order > 0 THEN ci.nr_order 
                ELSE NULL 
            END) AS avg_order_of_roles
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name
),
MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id, 
        COALESCE(mk.keyword_count, 0) AS total_keywords,
        mv.production_year,
        RANK() OVER (ORDER BY COALESCE(mk.keyword_count, 0) DESC) AS keyword_rank
    FROM 
        aka_title m
    LEFT JOIN 
        MovieKeywordCounts mk ON m.id = mk.movie_id
    JOIN 
        RecursiveMovieSequences mv ON m.id = mv.movie_id
)
SELECT 
    a.actor_name,
    md.movie_title,
    md.production_year,
    md.total_keywords,
    ai.total_movies,
    ai.lead_roles,
    ai.avg_order_of_roles
FROM 
    ActorInfo ai
JOIN 
    cast_info ci ON ai.actor_name = (SELECT name FROM aka_name WHERE person_id = ci.person_id LIMIT 1)
JOIN 
    MovieDetails md ON ci.movie_id = md.movie_id
WHERE 
    md.total_keywords > 2
ORDER BY 
    ai.total_movies DESC, 
    md.keyword_rank ASC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY
UNION ALL
SELECT 
    'Unknown Actor' AS actor_name,
    title.title AS movie_title,
    NULL AS production_year,
    COUNT(DISTINCT mk.keyword_id) AS total_keywords,
    NULL AS total_movies,
    NULL AS lead_roles,
    NULL AS avg_order_of_roles
FROM 
    aka_title title
LEFT JOIN 
    movie_keyword mk ON title.id = mk.movie_id
WHERE 
    title.production_year = 2023 
GROUP BY 
    title.title
HAVING 
    COUNT(mk.keyword_id) = 0
ORDER BY 
    title.title
LIMIT 5;
