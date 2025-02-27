WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN movie_companies mc ON mc.movie_id = t.movie_id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.movie_id
    LEFT JOIN keyword k ON k.id = mk.keyword_id
    GROUP BY 
        t.id, t.title, t.production_year
),
actor_movie_count AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(CASE WHEN ci.role_id IS NULL THEN 0 ELSE 1 END) AS has_role_ratio
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
qualified_actors AS (
    SELECT 
        ak.person_id,
        a.name AS actor_name,
        am.movie_count,
        am.has_role_ratio
    FROM 
        aka_name ak
    JOIN actor_movie_count am ON ak.person_id = am.person_id
    JOIN name a ON ak.person_id = a.imdb_id
    WHERE 
        am.movie_count >= 5 AND 
        am.has_role_ratio >= 0.75
),
final_output AS (
    SELECT 
        md.title,
        md.production_year,
        md.company_count,
        qa.actor_name,
        qa.movie_count
    FROM 
        movie_details md
    INNER JOIN qualified_actors qa ON md.title_id IN (
        SELECT 
            ci.movie_id 
        FROM 
            cast_info ci 
        WHERE 
            ci.person_id = qa.person_id
    )
    WHERE 
        md.year_rank <= 3
)
SELECT 
    fo.title,
    fo.production_year,
    fo.company_count,
    fo.actor_name,
    fo.movie_count
FROM 
    final_output fo
WHERE 
    fo.company_count > 1
ORDER BY 
    fo.production_year DESC,
    fo.title;
