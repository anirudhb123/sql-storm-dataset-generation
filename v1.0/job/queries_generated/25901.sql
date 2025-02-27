WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT c.name) AS cast_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT cn.name) AS companies
    FROM 
        aka_title AS m
    LEFT JOIN 
        cast_info AS ci ON ci.movie_id = m.id
    LEFT JOIN 
        aka_name AS c ON c.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword AS mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword AS k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_companies AS mc ON mc.movie_id = m.id
    LEFT JOIN 
        company_name AS cn ON cn.id = mc.company_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id
),
MovieInfo AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_names,
        md.keywords,
        md.companies,
        COALESCE(mi.info, 'No additional info') AS extra_info
    FROM 
        MovieDetails AS md
    LEFT JOIN 
        movie_info AS mi ON mi.movie_id = md.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.cast_names,
    m.keywords,
    m.companies,
    m.extra_info
FROM 
    MovieInfo AS m
ORDER BY 
    m.production_year DESC, 
    m.title ASC
LIMIT 100;
This SQL query creates a common table expression (CTE) called `MovieDetails` to aggregate information from several tables related to movies, cast, keywords, and companies involved. It then uses another CTE `MovieInfo` to join this aggregate data with additional movie information (like synopsis). Finally, it selects the first 100 rows, ordered by production year and title for a clear view of recent movies and their details.
