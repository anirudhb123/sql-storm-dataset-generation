WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS actor_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ca ON t.id = ca.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 

CompanyMovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id 
    GROUP BY 
        m.movie_id
),

FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cm.companies,
        cm.keywords
    FROM 
        RankedMovies rm
    JOIN 
        CompanyMovieInfo cm ON rm.movie_id = cm.movie_id
    WHERE 
        rm.actor_rank <= 5 AND
        (rm.production_year > 2000 AND cm.keywords IS NOT NULL) 
)

SELECT 
    fm.title,
    fm.production_year,
    fm.companies,
    COALESCE(fm.keywords, 'No Keywords') AS effective_keywords,
    COUNT(DISTINCT ca.person_id) AS total_cast,
    COUNT(DISTINCT CASE WHEN ca.role_id IS NULL THEN ca.person_id END) AS unnamed_roles,
    SUM(CASE 
            WHEN ca.nr_order IS NOT NULL THEN 1 
            ELSE 0 
        END) FILTER (WHERE ca.note LIKE '%lead%') AS lead_roles
FROM 
    FilteredMovies fm
LEFT JOIN 
    cast_info ca ON fm.movie_id = ca.movie_id
GROUP BY 
    fm.title, fm.production_year, fm.companies, fm.keywords
ORDER BY 
    fm.production_year DESC, total_cast DESC;
