WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
ActorMovieCount AS (
    SELECT 
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
CompanyMovieInfo AS (
    SELECT 
        cn.name AS company_name,
        mt.info AS movie_info,
        COUNT(DISTINCT mc.movie_id) AS total_movies
    FROM 
        company_name cn
    JOIN 
        movie_companies mc ON cn.id = mc.company_id
    JOIN 
        movie_info mt ON mc.movie_id = mt.movie_id
    GROUP BY 
        cn.name, mt.info
)
SELECT 
    rt.title,
    rt.production_year,
    ac.movie_count,
    cm.company_name,
    cm.movie_info,
    cm.total_movies
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorMovieCount ac ON rt.title_rank = ac.movie_count
LEFT JOIN 
    CompanyMovieInfo cm ON rt.production_year = cm.total_movies
WHERE 
    rt.production_year >= 1990
ORDER BY 
    rt.production_year DESC, rt.title;
