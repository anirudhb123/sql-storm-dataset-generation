WITH RankedTitles AS (
    SELECT 
        t.title, 
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM 
        title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name cn ON cn.id = mc.company_id
    JOIN 
        complete_cast cc ON cc.movie_id = t.id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id AND ci.person_id = cc.subject_id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    WHERE 
        cn.country_code = 'USA'
),

KeywordCounts AS (
    SELECT 
        mt.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        movie_info mi ON mk.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')
    GROUP BY 
        mt.movie_id
)

SELECT 
    rt.title, 
    rt.production_year, 
    rt.actor_name, 
    kc.keyword_count
FROM 
    RankedTitles rt
LEFT JOIN 
    KeywordCounts kc ON kc.movie_id = rt.id
WHERE 
    rt.rn = 1 
ORDER BY 
    rt.production_year DESC, 
    kc.keyword_count DESC
LIMIT 50;
