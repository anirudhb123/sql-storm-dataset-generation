WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY LENGTH(a.title) DESC) AS title_rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
),
PersonRoleAggregate AS (
    SELECT 
        c.person_role_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT p.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    GROUP BY 
        c.person_role_id
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
)
SELECT 
    rt.title,
    rt.production_year,
    rt.keyword,
    pra.actor_names,
    pra.movie_count
FROM 
    RankedTitles rt
JOIN 
    PersonRoleAggregate pra ON rt.production_year = (SELECT MAX(production_year) FROM aka_title WHERE id IN (SELECT movie_id FROM movie_keyword WHERE keyword_id IN (SELECT id FROM keyword WHERE keyword ILIKE '%' || rt.keyword || '%')))
ORDER BY 
    rt.production_year DESC, 
    rt.title_rank ASC;
