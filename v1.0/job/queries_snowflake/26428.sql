
WITH RankedTitles AS (
    SELECT 
        a.id AS title_id,
        a.title,
        a.production_year,
        k.keyword AS keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY k.keyword) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),

ActorPerformance AS (
    SELECT 
        c.movie_id,
        COUNT(*) AS actor_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors_list
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),

CompanyMovies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    rt.title,
    rt.production_year,
    rt.keyword,
    ap.actor_count,
    ap.actors_list,
    cm.company_names
FROM 
    RankedTitles rt
JOIN 
    ActorPerformance ap ON rt.title_id = ap.movie_id
JOIN 
    CompanyMovies cm ON rt.title_id = cm.movie_id
WHERE 
    rt.rank = 1 
    AND rt.production_year >= 2000
ORDER BY 
    rt.production_year DESC, 
    rt.title;
