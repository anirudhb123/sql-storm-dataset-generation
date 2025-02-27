WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        a.name AS actor_name, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        cn.country_code = 'USA' AND 
        t.production_year >= 2000
), RecentMovies AS (
    SELECT 
        title, 
        production_year, 
        actor_name
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    r.title, 
    r.production_year, 
    r.actor_name,
    ci.note AS role_note,
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
FROM 
    RecentMovies r
LEFT JOIN 
    cast_info ci ON r.actor_name = (SELECT a.name FROM aka_name a WHERE a.person_id = ci.person_id)
LEFT JOIN 
    movie_keyword mk ON r.title = (SELECT t.title FROM title t WHERE t.id = mk.movie_id)
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
GROUP BY 
    r.title, 
    r.production_year, 
    r.actor_name, 
    ci.note
ORDER BY 
    r.production_year DESC, 
    r.title;
