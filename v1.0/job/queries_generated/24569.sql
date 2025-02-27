WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.id) DESC) AS rank_order
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_order <= 3
),
MovieDetails AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        cast_info ci ON fm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON fm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        fm.movie_id, fm.title, fm.production_year
),
CompanyInformation AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
FinalReport AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.actor_names,
        md.keyword_count,
        COALESCE(ci.company_names, 'No companies') AS company_names,
        ci.company_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyInformation ci ON md.movie_id = ci.movie_id
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.actor_names,
    fr.keyword_count,
    fr.company_names,
    fr.company_count,
    CASE 
        WHEN fr.keyword_count > 5 THEN 'High Keyword Usage'
        WHEN fr.keyword_count BETWEEN 3 AND 5 THEN 'Moderate Keyword Usage'
        ELSE 'Low Keyword Usage'
    END AS keyword_usage_category,
    CASE 
        WHEN fr.company_count IS NULL THEN 'No Production Companies'
        ELSE 'Has Production Companies'
    END AS company_status
FROM 
    FinalReport fr
WHERE 
    fr.production_year BETWEEN 2000 AND 2023
ORDER BY 
    fr.production_year DESC, 
    fr.movie_id;
