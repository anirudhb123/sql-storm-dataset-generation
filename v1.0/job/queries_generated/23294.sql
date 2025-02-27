WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast,
        ARRAY_AGG(DISTINCT c.name) AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.*, 
        CASE 
            WHEN rm.rank_by_cast <= 3 THEN 'Top 3 Cast'
            ELSE 'Other'
        END AS cast_category
    FROM 
        RankedMovies rm
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') FILTER (WHERE cn.country_code IS NOT NULL) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.cast_category,
    COALESCE(cd.company_count, 0) AS company_count,
    COALESCE(cd.companies, 'No companies') AS companies,
    CASE 
        WHEN tm.production_year = 2022 THEN 'Recent Release'
        WHEN tm.production_year < 2000 THEN 'Classic'
        ELSE 'Modern'
    END AS era,
    (SELECT AVG(cast_count) FROM TopMovies) AS average_cast_count,
    (SELECT STRING_AGG(DISTINCT name, ', ') FROM char_name) AS all_character_names
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyDetails cd ON tm.movie_id = cd.movie_id
WHERE 
    tm.rank_by_cast <= 3 OR cd.company_count > 0
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC
LIMIT 50;
