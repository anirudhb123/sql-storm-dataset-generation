WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), ActorStats AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        a.person_id
), MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    a.name,
    as.movie_count,
    as.avg_order,
    mk.keywords
FROM 
    RankedTitles rt
LEFT JOIN 
    cast_info ci ON rt.title_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    ActorStats as ON a.person_id = as.person_id
LEFT JOIN 
    MovieKeywords mk ON rt.title_id = mk.movie_id
WHERE 
    rt.title_rank <= 5
    AND (as.movie_count > 0 OR mk.keywords IS NOT NULL)
ORDER BY 
    rt.production_year DESC, 
    a.name;
