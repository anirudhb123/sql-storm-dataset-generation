WITH Movie_Aggregates AS (
    SELECT 
        t.title AS movie_title, 
        t.production_year, 
        COUNT(DISTINCT mi.info) AS info_count,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
), 
Person_Aggregates AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.id, a.name
)
SELECT 
    ma.movie_title,
    ma.production_year,
    ma.info_count,
    ma.keywords,
    ma.company_names,
    pa.actor_name,
    pa.movie_count,
    pa.movies
FROM 
    Movie_Aggregates ma
JOIN 
    cast_info ci ON ci.movie_id IN (SELECT m.id FROM title m WHERE m.production_year = ma.production_year)
JOIN 
    Person_Aggregates pa ON ci.person_id IN (SELECT p.id FROM aka_name p WHERE p.name IS NOT NULL)
WHERE 
    ma.info_count > 5
ORDER BY 
    ma.production_year DESC, 
    ma.movie_title;
