WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ak.name ASC) AS actor_rank
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000  -- Filter for movies from 2000 onwards
),

KeywordCounts AS (
    SELECT 
        m.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        title AS m
    LEFT JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    GROUP BY 
        m.id
),

MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    rt.title,
    rt.production_year,
    rt.actor_name,
    kc.keyword_count,
    mc.company_count
FROM 
    RankedTitles AS rt
LEFT JOIN 
    KeywordCounts AS kc ON rt.production_year = kc.movie_id
LEFT JOIN 
    MovieCompanies AS mc ON rt.production_year = mc.movie_id
WHERE 
    rt.actor_rank = 1  -- Select only the first actor alphabetically
ORDER BY 
    rt.production_year DESC, 
    rt.title ASC;
