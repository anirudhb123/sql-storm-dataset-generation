WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.id) AS cast_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT co.name) AS companies
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON cc.movie_id = t.id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    JOIN 
        aka_name c ON c.id = ci.person_id
    JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name co ON co.id = mc.company_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
InfoDetails AS (
    SELECT 
        m.movie_id,
        GROUP_CONCAT(DISTINCT mi.info) AS movie_infos
    FROM 
        MovieDetails m
    LEFT JOIN 
        movie_info mi ON mi.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_names,
    md.keywords,
    md.companies,
    COALESCE(id.movie_infos, 'No additional info') AS additional_info
FROM 
    MovieDetails md
LEFT JOIN 
    InfoDetails id ON id.movie_id = md.movie_id
ORDER BY 
    md.production_year DESC, 
    md.title;
