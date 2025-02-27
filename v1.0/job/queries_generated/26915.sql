WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name) AS actors
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year
),
KeywordDetails AS (
    SELECT 
        m.movie_id,
        GROUP_CONCAT(k.keyword ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
MovieInfo AS (
    SELECT 
        md.movie_title,
        md.production_year,
        kd.keywords,
        md.actors
    FROM 
        MovieDetails md
    LEFT JOIN 
        KeywordDetails kd ON md.movie_title = (
            SELECT t.title FROM title t WHERE t.production_year = md.production_year LIMIT 1
        )
)
SELECT 
    mi.movie_title,
    mi.production_year,
    mi.actors,
    mi.keywords,
    COALESCE(NULLIF(LENGTH(mi.keywords), 0), 'No Keywords') AS keyword_summary
FROM 
    MovieInfo mi
ORDER BY 
    mi.production_year DESC, 
    mi.movie_title;
