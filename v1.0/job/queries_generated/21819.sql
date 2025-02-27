WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY c.nr_order) AS role_order,
        COUNT(c.id) OVER (PARTITION BY t.id) AS total_cast_members
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        role_order,
        total_cast_members
    FROM 
        RankedMovies
    WHERE 
        role_order IS NOT NULL
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name || ' (' || ct.kind || ')', ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
GenreKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        ci.companies,
        gk.keywords,
        CASE 
            WHEN fm.total_cast_members > 0 THEN 'Has Cast'
            ELSE 'No Cast'
        END AS cast_status
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        CompanyInfo ci ON fm.movie_id = ci.movie_id
    LEFT JOIN 
        GenreKeywords gk ON fm.movie_id = gk.movie_id
)
SELECT 
    title,
    production_year,
    companies,
    keywords,
    cast_status,
    LEAD(title) OVER (ORDER BY production_year) AS next_movie_title,
    LAG(title) OVER (ORDER BY production_year) AS previous_movie_title
FROM 
    MovieDetails
WHERE 
    production_year BETWEEN 2000 AND 2020
    AND (companies IS NOT NULL OR keywords IS NOT NULL)
ORDER BY 
    production_year ASC, title ASC;
