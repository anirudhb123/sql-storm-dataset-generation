WITH RecursiveInfo AS (
    SELECT 
        ca.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        cast_info ca
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    JOIN 
        aka_title t ON ca.movie_id = t.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        ca.person_id, a.name, t.title, t.production_year, k.keyword
),
RankedInfo AS (
    SELECT 
        r.*,
        ROW_NUMBER() OVER (PARTITION BY r.person_id ORDER BY r.production_year DESC) AS rn
    FROM 
        RecursiveInfo r
)
SELECT 
    ri.actor_name,
    ri.movie_title,
    ri.production_year,
    ri.keyword,
    ri.company_count,
    ri.companies
FROM 
    RankedInfo ri
WHERE 
    ri.rn <= 5
ORDER BY 
    ri.actor_name, ri.production_year DESC;
