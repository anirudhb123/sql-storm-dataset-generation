
WITH RECURSIVE MovieCTE AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mc.depth + 1
    FROM 
        aka_title m
    JOIN 
        MovieCTE mc ON m.episode_of_id = mc.movie_id
    WHERE 
        mc.depth < 5
),
RankedCast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    m.title,
    m.production_year,
    COUNT(DISTINCT c.actor_rank) AS number_of_actors,
    r.companies,
    MAX(c.actor_name) AS lead_actor,
    CASE 
        WHEN m.production_year < 2010 THEN 'Classic'
        ELSE 'Modern'
    END AS era,
    COALESCE(ki.keyword, 'No Keywords') AS movie_keyword
FROM 
    MovieCTE m
LEFT JOIN 
    RankedCast c ON c.movie_id = m.movie_id
LEFT JOIN 
    MovieCompanies r ON r.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    keyword ki ON ki.id = mk.keyword_id
GROUP BY 
    m.movie_id, m.title, m.production_year, r.companies, ki.keyword
HAVING 
    COUNT(DISTINCT c.actor_rank) > 2;
