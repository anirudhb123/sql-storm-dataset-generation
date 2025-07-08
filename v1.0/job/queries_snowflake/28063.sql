WITH RankedTitles AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.title, a.production_year
),
PeopleWithRoles AS (
    SELECT 
        p.name AS person_name,
        c.nr_order AS role_order,
        t.title AS movie_title,
        a.name AS character_name,
        RANK() OVER (PARTITION BY t.production_year ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        title t ON c.movie_id = t.id
    JOIN 
        name p ON a.person_id = p.imdb_id
),
CompanyCount AS (
    SELECT 
        m.id AS movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        title m ON mc.movie_id = m.id
    GROUP BY 
        m.id
)
SELECT 
    rt.movie_title,
    rt.production_year,
    rt.title_rank,
    rt.keywords,
    p.person_name,
    p.role_order,
    p.character_name,
    p.role_rank,
    cc.company_count
FROM 
    RankedTitles rt
LEFT JOIN 
    PeopleWithRoles p ON rt.movie_title = p.movie_title
LEFT JOIN 
    CompanyCount cc ON rt.movie_title = (SELECT title FROM title WHERE id = cc.movie_id)
WHERE 
    rt.production_year >= 2000
ORDER BY 
    rt.production_year ASC, 
    rt.title_rank ASC, 
    p.role_rank ASC;
