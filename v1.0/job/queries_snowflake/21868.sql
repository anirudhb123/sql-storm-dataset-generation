
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title AS t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCompany AS (
    SELECT
        c.person_id,
        m.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM
        cast_info AS c
    JOIN 
        movie_companies AS m ON c.movie_id = m.movie_id
    JOIN 
        company_name AS co ON m.company_id = co.id
    JOIN 
        company_type AS ct ON m.company_type_id = ct.id
    WHERE 
        co.country_code IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword AS m
    JOIN 
        keyword AS k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
ActorNames AS (
    SELECT 
        a.person_id,
        LISTAGG(n.name, ', ') WITHIN GROUP (ORDER BY n.name) AS actor_names,
        MAX(n.gender) AS gender  
    FROM 
        aka_name AS a
    JOIN 
        name AS n ON a.person_id = n.imdb_id
    GROUP BY 
        a.person_id
)
SELECT 
    rt.title,
    rt.production_year,
    act.actor_names,
    act.gender,
    kc.keywords,
    ac.company_name,
    ac.company_type
FROM 
    RankedTitles AS rt
LEFT JOIN 
    ActorCompany AS ac ON ac.movie_id = rt.title_id
LEFT JOIN 
    MovieKeywords AS kc ON kc.movie_id = rt.title_id
LEFT JOIN 
    ActorNames AS act ON act.person_id = ac.person_id
WHERE 
    rt.title_rank <= 5  
    AND (rt.production_year < 2000 OR act.gender IS NOT NULL)  
ORDER BY 
    rt.production_year DESC, 
    rt.title;
