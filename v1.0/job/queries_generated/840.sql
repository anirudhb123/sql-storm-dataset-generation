WITH MovieCast AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL
), 

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY mk.movie_id ORDER BY k.keyword) AS keyword_order
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
), 

MovieCompanies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        cnt.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY cn.name) AS company_order
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type cnt ON mc.company_type_id = cnt.id
)

SELECT 
    mc.movie_id,
    mt.title,
    mt.production_year,
    STRING_AGG(DISTINCT ac.actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT mc.company_name || ' (' || mc.company_type || ')', ', ') AS production_companies
FROM 
    MovieCast ac
JOIN 
    aka_title mt ON ac.movie_id = mt.movie_id
JOIN 
    MovieKeywords mk ON ac.movie_id = mk.movie_id
JOIN 
    MovieCompanies mc ON ac.movie_id = mc.movie_id
WHERE 
    mt.production_year >= 2000
GROUP BY 
    mc.movie_id, mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT ac.actor_id) > 2
ORDER BY 
    mt.production_year DESC, mt.title;
