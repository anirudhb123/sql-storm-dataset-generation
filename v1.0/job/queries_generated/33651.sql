WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank,
        COUNT(DISTINCT ca.person_id) AS actor_count
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ca ON at.id = ca.movie_id
    GROUP BY 
        at.title, at.production_year
),
CombinedResults AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        rt.title_rank,
        rt.actor_count,
        COALESCE(rt.actor_count, 0) AS actor_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        RankedTitles rt ON mh.title = rt.title AND mh.production_year = rt.production_year
)
SELECT 
    cr.title,
    cr.production_year,
    cr.actor_count,
    CASE 
        WHEN cr.actor_count > 10 THEN 'Blockbuster'
        WHEN cr.actor_count BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Indie'
    END AS classification,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names
FROM 
    CombinedResults cr
LEFT JOIN 
    movie_companies mc ON cr.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    cr.actor_count IS NOT NULL
GROUP BY 
    cr.title,
    cr.production_year,
    cr.actor_count
ORDER BY 
    cr.production_year DESC, 
    cr.actor_count DESC;
