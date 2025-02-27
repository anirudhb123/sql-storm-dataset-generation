WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count
    FROM 
        aka_title m
    LEFT JOIN 
        ActorCounts ac ON m.id = ac.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    COALESCE(k.keyword, 'No Keywords') AS keyword,
    COALESCE(c.name, 'Unknown Company') AS company_name,
    COUNT(DISTINCT c.id) OVER (PARTITION BY md.movie_id) AS company_count,
    STRING_AGG(DISTINCT a.name, ', ') AS actors
FROM 
    MovieDetails md
LEFT JOIN 
    movie_companies mc ON md.movie_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword mk ON md.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
WHERE 
    md.actor_count > 3 AND (md.production_year > 2000)
GROUP BY 
    md.title, md.production_year, md.actor_count, k.keyword, c.name
ORDER BY 
    md.production_year DESC, md.actor_count DESC, md.title;
