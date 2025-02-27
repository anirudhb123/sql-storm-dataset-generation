WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS alternative_names,
        GROUP_CONCAT(DISTINCT c.name) AS companies,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT ca.person_id) AS cast_count
    FROM 
        title t
    LEFT JOIN aka_title ak ON ak.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_name c ON c.id = mc.company_id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword k ON k.id = mk.keyword_id
    LEFT JOIN cast_info ca ON ca.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        alternative_names,
        companies,
        keywords,
        cast_count,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        MovieDetails
    WHERE 
        production_year >= 2000
)
SELECT 
    pm.movie_id,
    pm.title,
    pm.production_year,
    pm.alternative_names,
    pm.companies,
    pm.keywords,
    pm.cast_count
FROM 
    PopularMovies pm
WHERE 
    pm.rank <= 10
ORDER BY 
    pm.cast_count DESC;
