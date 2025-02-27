WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT 
        ak.name AS actor_name,
        c.movie_id,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY ak.name) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON c.movie_id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY m.id, m.title
)
SELECT 
    rt.title,
    rt.production_year,
    ai.actor_name,
    ai.company_type,
    mwk.keywords,
    CASE 
        WHEN ai.actor_rank = 1 THEN 'Lead Actor'
        WHEN ai.actor_rank BETWEEN 2 AND 5 THEN 'Supporting Actor'
        ELSE 'Background Actor'
    END AS actor_role
FROM 
    RankedTitles rt
JOIN 
    ActorInfo ai ON rt.title = ai.movie_id
JOIN 
    MovieWithKeywords mwk ON mwk.movie_id = rt.title
WHERE 
    rt.title_rank <= 10
AND 
    rt.production_year >= 2000
ORDER BY 
    rt.production_year DESC, rt.title;
