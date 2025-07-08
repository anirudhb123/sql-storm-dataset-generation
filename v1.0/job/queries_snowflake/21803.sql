
WITH RECURSIVE title_hierarchy AS (
    SELECT 
        t.id AS title_id, 
        t.title,
        t.production_year,
        t.kind_id,
        t.imdb_index,
        0 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000

    UNION ALL 

    SELECT 
        m.id AS title_id,
        m.title,
        m.production_year,
        m.kind_id,
        m.imdb_index,
        th.level + 1 AS level
    FROM 
        title_hierarchy th
    JOIN 
        movie_link ml ON th.title_id = ml.movie_id
    JOIN 
        title m ON ml.linked_movie_id = m.id
    WHERE 
        th.level < 3
),

actor_info AS (
    SELECT 
        ak.name AS actor_name,
        ak.id AS actor_id,
        SUM(CASE 
                WHEN ci.note IS NOT NULL THEN 1
                ELSE 0 
            END) AS roles_count,
        COUNT(DISTINCT ci.movie_id) AS movies_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    WHERE 
        ak.name NOT LIKE 'Unknown%' 
    GROUP BY 
        ak.id, ak.name
),

top_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        ROW_NUMBER() OVER (ORDER BY COUNT(cm.company_id) DESC) AS rank_by_companies
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies cm ON t.id = cm.movie_id
    GROUP BY 
        t.id, t.title
    HAVING 
        COUNT(DISTINCT cm.company_id) > 5
),

keywords_summary AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    th.title,
    th.production_year,
    ai.actor_name,
    ai.roles_count,
    ai.movies_count,
    ks.keywords
FROM 
    title_hierarchy th
LEFT JOIN 
    actor_info ai ON th.title_id IN (
        SELECT 
            ci.movie_id 
        FROM 
            cast_info ci 
        WHERE 
            ci.person_role_id IN (SELECT id FROM role_type WHERE role LIKE '%Lead%')
    )
LEFT JOIN 
    keywords_summary ks ON th.title_id = ks.movie_id
WHERE 
    th.level > 0 
    AND (ai.roles_count > 1 OR ai.movies_count = 0)
ORDER BY 
    th.production_year DESC, 
    th.title
LIMIT 100;
