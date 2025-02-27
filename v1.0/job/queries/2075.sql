WITH movie_titles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title at
    LEFT JOIN 
        movie_companies mc ON at.movie_id = mc.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
cast_roles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actors
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_summary AS (
    SELECT 
        mt.title_id,
        mt.title,
        mt.production_year,
        COALESCE(cr.actor_count, 0) AS actor_count,
        COALESCE(ks.keywords, 'None') AS keywords,
        mt.company_count
    FROM 
        movie_titles mt
    LEFT JOIN 
        cast_roles cr ON mt.title_id = cr.movie_id
    LEFT JOIN 
        keyword_summary ks ON mt.title_id = ks.movie_id
)
SELECT 
    ms.title,
    ms.production_year,
    ms.actor_count,
    ms.keywords,
    ms.company_count,
    CASE 
        WHEN ms.actor_count > 5 THEN 'Ensemble Cast'
        WHEN ms.company_count > 3 THEN 'Major Production'
        ELSE 'Independent Film' 
    END AS classification
FROM 
    movie_summary ms
WHERE 
    ms.production_year BETWEEN 2000 AND 2023
ORDER BY 
    ms.production_year DESC, 
    ms.actor_count DESC;
