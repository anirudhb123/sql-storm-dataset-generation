WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cs.company_count,
        cs.company_names,
        (SELECT 
            COUNT(*) 
         FROM 
            movie_info mi 
         WHERE 
            mi.movie_id = rm.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')) AS budget_count,
        (SELECT 
            GROUP_CONCAT(info) 
         FROM 
            movie_info mi 
         WHERE 
            mi.movie_id = rm.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'plot')) AS plot_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyStats cs ON rm.movie_id = cs.movie_id
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.company_count, 0) AS company_count,
    COALESCE(md.company_names, 'None') AS company_names,
    md.budget_count,
    COALESCE(md.plot_info, 'No plot available') AS plot_info
FROM 
    MovieDetails md
WHERE 
    md.rank <= 5
ORDER BY 
    md.production_year DESC, 
    md.company_count DESC;
