WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT c.name) AS cast_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COALESCE(cn.name, 'Unknown') AS company_name
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year, cn.name
),
MovieInfo AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_names,
        md.keywords,
        md.company_name,
        COUNT(DISTINCT mi.info) AS info_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        movie_info mi ON md.movie_id = mi.movie_id
    GROUP BY 
        md.movie_id, md.title, md.production_year, md.cast_names, md.keywords, md.company_name
)
SELECT 
    movie_id,
    title,
    production_year,
    cast_names,
    keywords,
    company_name,
    info_count
FROM 
    MovieInfo
ORDER BY 
    production_year DESC, title;
