WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    LEFT JOIN 
        aka_name a ON a.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieInfo AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_names,
        md.keywords,
        md.company_count,
        mi.info AS additional_info
    FROM 
        MovieDetails md
    LEFT JOIN 
        movie_info mi ON mi.movie_id = md.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
),
FinalResults AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_names,
        keywords,
        company_count,
        COALESCE(additional_info, 'No Synopsis Available') AS synopsis
    FROM 
        MovieInfo
)

SELECT 
    movie_id,
    title,
    production_year,
    cast_names,
    keywords,
    company_count,
    synopsis
FROM 
    FinalResults
ORDER BY 
    production_year DESC, title;

