WITH recursive movie_hierarchy AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        coalesce(c.name, 'Unknown') AS company_name, 
        k.keyword AS movie_keyword
    FROM title t
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year >= 2000
    UNION ALL
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        coalesce(c.name, 'Unknown') AS company_name, 
        k.keyword AS movie_keyword
    FROM movie_hierarchy mh
    JOIN title t ON t.id = mh.movie_id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year >= 2000
)
SELECT 
    mh.title, 
    mh.production_year, 
    mh.company_name, 
    ARRAY_AGG(DISTINCT mh.movie_keyword) AS keywords
FROM movie_hierarchy mh
GROUP BY mh.title, mh.production_year, mh.company_name
ORDER BY mh.production_year DESC;
