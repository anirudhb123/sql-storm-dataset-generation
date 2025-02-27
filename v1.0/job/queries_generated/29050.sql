WITH ActorTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year AS movie_year,
        c.note AS role_note
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL
),

CompanyMovies AS (
    SELECT 
        cn.name AS company_name,
        mt.title AS movie_title,
        mt.production_year AS production_year,
        mt.note AS movie_note
    FROM 
        company_name cn
    JOIN 
        movie_companies mc ON cn.id = mc.company_id
    JOIN 
        aka_title mt ON mc.movie_id = mt.movie_id
    WHERE 
        cn.name IS NOT NULL
),

KeywordStats AS (
    SELECT 
        mt.title AS movie_title,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.title
),

FinalReport AS (
    SELECT 
        at.actor_name,
        at.movie_title,
        at.movie_year,
        cm.company_name,
        ks.keyword_count,
        at.role_note
    FROM 
        ActorTitles at
    LEFT JOIN 
        CompanyMovies cm ON at.movie_title = cm.movie_title AND at.movie_year = cm.production_year
    LEFT JOIN 
        KeywordStats ks ON at.movie_title = ks.movie_title
)

SELECT 
    actor_name,
    movie_title,
    movie_year,
    company_name,
    keyword_count,
    role_note
FROM 
    FinalReport
ORDER BY 
    movie_year DESC, actor_name;
