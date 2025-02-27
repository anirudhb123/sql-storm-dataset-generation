WITH MovieDetail AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT c.name) AS cast_names,
        kt.keyword AS keyword
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        title t ON mt.id = t.id
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2022
        AND kt.keyword IS NOT NULL
        AND ak.name IS NOT NULL
    GROUP BY 
        mt.title, mt.production_year, kt.keyword
), AverageProductionYear AS (
    SELECT 
        AVG(production_year) AS avg_year
    FROM 
        aka_title
)
SELECT 
    md.movie_title,
    md.production_year,
    md.aka_names,
    md.cast_names,
    md.keyword,
    (SELECT avg_year FROM AverageProductionYear) AS average_production_year
FROM 
    MovieDetail md
WHERE 
    md.production_year > (SELECT avg_year FROM AverageProductionYear)
ORDER BY 
    md.production_year DESC;

