WITH recursive actor_hierarchy AS (
    SELECT 
        ci.person_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        SUM(CASE WHEN ti.production_year IS NOT NULL THEN 1 ELSE 0 END) AS produced_movies
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        aka_title ti ON ci.movie_id = ti.id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        ci.person_id, a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) >= 5
),
top_actors AS (
    SELECT 
        actor_name, 
        movie_count, 
        produced_movies, 
        ROW_NUMBER() OVER (ORDER BY movie_count DESC) AS rank
    FROM 
        actor_hierarchy
),
movie_generics AS (
    SELECT DISTINCT 
        title.title, 
        k.keyword
    FROM 
        title 
    LEFT JOIN 
        movie_keyword mk ON title.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
detailed_movie_info AS (
    SELECT 
        mt.movie_id,
        m.title,
        COALESCE(COUNT(mk.id), 0) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS production_companies,
        MIN(mi.info) AS info_detail
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id
)
SELECT 
    ta.actor_name,
    ta.movie_count,
    dm.title,
    dm.keyword_count,
    dm.production_companies,
    CASE 
        WHEN dm.keyword_count > 5 THEN 'Highly Taggable'
        WHEN dm.keyword_count > 0 THEN 'Moderately Taggable'
        ELSE 'Not Taggable'
    END AS tagability_level,
    COALESCE(dm.info_detail, 'No Info') AS movie_detail
FROM 
    top_actors ta
JOIN 
    detailed_movie_info dm ON ta.movie_count = dm.keyword_count
WHERE 
    dm.production_companies IS NOT NULL 
    AND ta.rank <= 10
ORDER BY 
    ta.movie_count DESC, dm.production_companies ASC;
