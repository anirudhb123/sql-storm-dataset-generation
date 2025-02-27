WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.kind, ', ') AS company_types
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieInfo AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        COUNT(DISTINCT ci.id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT mc.id) AS company_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        cast_info ci ON md.movie_id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON md.movie_id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON md.movie_id = mc.movie_id
    GROUP BY 
        md.movie_id, md.movie_title, md.production_year
)
SELECT 
    mi.movie_id,
    mi.movie_title,
    mi.production_year,
    mi.cast_count,
    mi.keyword_count,
    mi.company_count,
    CASE 
        WHEN mi.cast_count > 0 AND mi.keyword_count > 0 THEN 'High'
        WHEN mi.cast_count > 0 THEN 'Medium'
        ELSE 'Low'
    END AS engagement_level
FROM 
    MovieInfo mi
ORDER BY 
    mi.production_year DESC, 
    mi.cast_count DESC, 
    mi.keyword_count DESC;
