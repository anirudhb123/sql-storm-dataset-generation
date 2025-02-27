WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast_size
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        movie_title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast_size <= 5 
),
MovieCompanies AS (
    SELECT 
        f.movie_title,
        f.production_year,
        COALESCE(gc.name, 'Unknown') AS company_name,
        COUNT(m.movie_id) AS movie_count
    FROM 
        FilteredMovies f
    LEFT JOIN 
        movie_companies m ON f.movie_title = (SELECT title FROM aka_title WHERE id = m.movie_id)
    LEFT JOIN 
        company_name gc ON m.company_id = gc.id
    GROUP BY 
        f.movie_title, f.production_year, gc.name
    ORDER BY 
        f.production_year DESC, movie_count DESC
),
MovieKeywords AS (
    SELECT 
        f.movie_title,
        f.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        FilteredMovies f
    JOIN 
        movie_keyword mk ON f.movie_title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        f.movie_title, f.production_year
),
FinalOutput AS (
    SELECT 
        mc.movie_title,
        mc.production_year,
        mc.company_name,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        (SELECT COUNT(*) FROM aka_name an WHERE an.person_id IN 
            (SELECT c.person_id FROM cast_info c 
             WHERE c.movie_id = (SELECT id FROM aka_title WHERE title = mc.movie_title LIMIT 1))
        ) AS cast_member_count
    FROM 
        MovieCompanies mc
    LEFT JOIN 
        MovieKeywords mk ON mc.movie_title = mk.movie_title AND mc.production_year = mk.production_year
)
SELECT 
    *,
    CASE 
        WHEN cast_member_count IS NULL THEN 'No cast members'
        WHEN cast_member_count > 10 THEN 'Ensemble cast'
        ELSE 'Small cast'
    END AS cast_size_description
FROM 
    FinalOutput
WHERE 
    production_year BETWEEN 2000 AND 2020
ORDER BY 
    production_year DESC, company_name;