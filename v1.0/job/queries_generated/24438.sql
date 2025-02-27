WITH RECURSIVE title_hierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        t.episode_of_id,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL  -- Starting nodes for the hierarchy

    UNION ALL

    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        t.episode_of_id,
        th.level + 1
    FROM 
        aka_title t
    INNER JOIN 
        title_hierarchy th ON t.episode_of_id = th.title_id
), 
actor_info AS (
    SELECT 
        a.id AS actor_id,
        ak.name,
        COUNT(ci.movie_id) AS total_movies,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        movie_keyword mk ON mk.movie_id = ci.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        ak.name IS NOT NULL  
    GROUP BY 
        a.id, ak.name
),
movie_info_summary AS (
    SELECT 
        mt.movie_id,
        CONCAT(mt.title, ' (', mt.production_year, ')') AS full_title,
        COUNT(ci.id) AS actor_count,
        SUM(CASE WHEN mi.info_type_id IS NOT NULL THEN 1 ELSE 0 END) AS info_count,
        STRING_AGG(DISTINCT comp.name, ', ') AS companies
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = mt.id
    LEFT JOIN 
        movie_info mi ON mt.id = mi.movie_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = mt.id
    LEFT JOIN 
        company_name comp ON mc.company_id = comp.id
    GROUP BY 
        mt.movie_id, mt.title, mt.production_year
),
final_summary AS (
    SELECT 
        t.title,
        t.production_year,
        t.actor_count,
        m.keywords,
        m.companies
    FROM 
        movie_info_summary t
    LEFT JOIN 
        actor_info m ON t.movie_id = m.actor_id
    WHERE 
        t.actor_count > 0  -- Only include movies with actors
)
SELECT 
    fh.title,
    fh.production_year,
    fh.actor_count,
    COALESCE(fh.keywords, 'No keywords') AS keywords,
    COALESCE(fh.companies, 'No associated companies') AS companies,
    ROW_NUMBER() OVER (PARTITION BY fh.production_year ORDER BY fh.actor_count DESC) AS rank_within_year
FROM 
    final_summary fh
WHERE 
    fh.production_year >= 2000  -- Filter for more recent films
ORDER BY 
    fh.production_year, actor_count DESC, title;
