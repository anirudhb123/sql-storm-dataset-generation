WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
ActorMovieCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
),
CompanyMovieInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        cn.country_code = 'USA'
)
SELECT 
    a.id AS actor_id,
    a.name,
    rt.title_id,
    rt.title,
    rt.production_year,
    amc.movie_count,
    cmi.company_name,
    cmi.company_type,
    rt.keyword
FROM 
    aka_name a
JOIN 
    ActorMovieCounts amc ON a.person_id = amc.person_id
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    RankedTitles rt ON ci.movie_id = rt.title_id
JOIN 
    CompanyMovieInfo cmi ON ci.movie_id = cmi.movie_id
WHERE 
    rt.rank = 1
ORDER BY 
    a.name, rt.production_year DESC;
