WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_cast,
        COUNT(c.person_id) AS total_cast
    FROM
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast
    FROM 
        RankedMovies
    WHERE 
        rank_cast <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.keyword_count, 0) AS keyword_count,
    COALESCE(md.companies, 'No Companies') AS companies,
    CASE 
        WHEN md.keyword_count > 10 THEN 'Highly Tagged'
        WHEN md.keyword_count BETWEEN 6 AND 10 THEN 'Moderately Tagged'
        ELSE 'Sparsely Tagged'
    END AS tag_category
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.keyword_count DESC
LIMIT 10;
