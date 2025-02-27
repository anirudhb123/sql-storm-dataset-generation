WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),

CastWithRoles AS (
    SELECT 
        ki.movie_id,
        ak.name AS actor_name,
        ct.kind AS role,
        COUNT(DISTINCT ci.person_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY 
        ki.movie_id, ak.name, ct.kind
),

MoviesWithKeywords AS (
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
    rt.title AS Movie_Title,
    rt.production_year AS Release_Year,
    cwr.actor_name AS Main_Actor,
    cwr.role AS Actor_Role,
    mwk.keywords AS Associated_Keywords,
    COUNT(DISTINCT ci.id) AS Number_Of_Casts
FROM 
    RankedTitles rt
LEFT JOIN 
    CastWithRoles cwr ON rt.title_id = cwr.movie_id AND cwr.role_count > 1
LEFT JOIN 
    MoviesWithKeywords mwk ON rt.title_id = mwk.movie_id
LEFT JOIN 
    complete_cast cc ON rt.title_id = cc.movie_id
WHERE 
    rt.title_rank <= 5
    AND rt.production_year BETWEEN 2000 AND 2023
    AND (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = rt.title_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%award%')) > 0
GROUP BY 
    rt.title, rt.production_year, cwr.actor_name, cwr.role, mwk.keywords
HAVING 
    COUNT(DISTINCT ci.person_id) IS NULL OR COUNT(DISTINCT ci.person_id) > 5
ORDER BY 
    rt.production_year DESC, rt.title ASC;

