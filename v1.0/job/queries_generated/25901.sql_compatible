
WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT c.name) AS cast_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
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
        m.id, m.title, m.production_year
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
