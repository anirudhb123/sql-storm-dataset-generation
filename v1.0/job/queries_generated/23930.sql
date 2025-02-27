WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast,
        COUNT(ci.person_id) AS total_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast = 1
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        ARRAY_AGG(DISTINCT c.name) AS cast_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        COUNT(DISTINCT mn.id) AS movie_companies_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
),
ExtensiveResults AS (
    SELECT 
        md.*,
        CASE 
            WHEN movie_companies_count IS NULL THEN 'No Companies'
            ELSE 'Has Companies'
        END AS company_status,
        COALESCE(STRING_AGG(DISTINCT ct.kind, ', '), 'No Type') AS company_types
    FROM 
        MovieDetails md
    LEFT JOIN 
        movie_companies mc ON md.movie_id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        md.title, md.production_year, movie_companies_count
)
SELECT 
    *,
    ROW_NUMBER() OVER (ORDER BY production_year DESC, title) AS row_num,
    CASE 
        WHEN production_year = (SELECT MAX(production_year) FROM aka_title) 
             THEN 'Latest Year'
        ELSE 'Earlier Year'
    END AS year_category
FROM 
    ExtensiveResults
ORDER BY 
    total_cast DESC, title ASC
LIMIT 10;
