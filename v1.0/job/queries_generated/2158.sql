WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COALESCE(comp.name, 'Independent') AS company_name
    FROM 
        RankedMovies rm
    LEFT JOIN 
        (SELECT 
            mk.movie_id,
            STRING_AGG(kw.keyword, ', ') AS keywords
        FROM 
            movie_keyword mk
        JOIN 
            keyword kw ON mk.keyword_id = kw.id
        GROUP BY 
            mk.movie_id) mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name comp ON mc.company_id = comp.id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.cast_count,
    md.keywords,
    COUNT(DISTINCT ci.person_id) AS unique_actors,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS actors_with_notes
FROM 
    MovieDetails md
LEFT JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
WHERE 
    md.rank <= 5
GROUP BY 
    md.movie_title, md.production_year, md.cast_count, md.keywords
ORDER BY 
    md.production_year DESC, md.cast_count DESC;
