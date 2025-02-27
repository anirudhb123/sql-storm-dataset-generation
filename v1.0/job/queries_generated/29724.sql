WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword AS movie_keyword,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name) AS cast_names,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS company_names
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
MovieInfo AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.movie_keyword,
        COUNT(DISTINCT md.cast_names) AS total_cast,
        COUNT(DISTINCT md.company_names) AS total_companies
    FROM 
        MovieDetails md
    GROUP BY 
        md.movie_id, md.title, md.production_year, md.movie_keyword
)
SELECT 
    mi.movie_id,
    mi.title,
    mi.production_year,
    mi.movie_keyword,
    mi.total_cast,
    mi.total_companies
FROM 
    MovieInfo mi
WHERE 
    mi.total_cast > 3 AND
    mi.production_year BETWEEN 2010 AND 2020
ORDER BY 
    mi.production_year DESC, 
    mi.total_cast DESC;

This SQL query constructs a Common Table Expression (CTE) that aggregates details about movies, including their titles, production years, associated keywords, cast names, and production companies. It filters for movies produced after 2000 and then further selects movies from 2010 to 2020 that have more than three cast members. The final output is ordered by production year in descending order and then by the count of cast members.
