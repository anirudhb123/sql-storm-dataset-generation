WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT g.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT p.name, ', ') AS cast,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword g ON mk.keyword_id = g.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name p ON ci.person_id = p.person_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
FinalResult AS (
    SELECT 
        md.*,
        COALESCE(rm.year_rank, 0) AS year_rank
    FROM 
        MovieDetails md
    LEFT JOIN 
        RankedMovies rm ON md.production_year = rm.production_year
)
SELECT 
    *,
    CASE 
        WHEN year_rank > 10 THEN 'Recent Hit'
        WHEN year_rank BETWEEN 5 AND 10 THEN 'Moderate Success'
        ELSE 'Classic'
    END AS movie_category
FROM 
    FinalResult
WHERE 
    company_count > 2
ORDER BY 
    production_year DESC, title;
