WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM title m
    WHERE m.season_nr IS NULL
    
    UNION ALL
    
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM MovieHierarchy mh
    JOIN title t ON t.episode_of_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rank_year
    FROM MovieHierarchy mh
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM RankedMovies rm
    WHERE rm.rank_year <= 5
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    ak.name AS actor_name,
    company.name AS production_company,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    AVG(COALESCE(mo.year, 0)) AS avg_company_year
FROM 
    FilteredMovies f
LEFT JOIN 
    cast_info ci ON ci.movie_id = f.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = f.movie_id
LEFT JOIN 
    company_name company ON company.id = mc.company_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = f.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    (SELECT 
        movie_id, 
        MIN(production_year) AS year 
     FROM title 
     GROUP BY movie_id) mo ON mo.movie_id = f.movie_id
GROUP BY 
    f.movie_id, f.title, f.production_year, ak.name, company.name
ORDER BY 
    f.production_year DESC, 
    f.title ASC
LIMIT 50;
