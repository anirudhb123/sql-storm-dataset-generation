WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieDetails AS (
    SELECT 
        rm.title,
        rm.production_year,
        COALESCE(mi.info, 'N/A') AS movie_info,
        COUNT(mc.company_id) AS company_count,
        STRING_AGG(cn.name, ', ') AS company_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mc ON rm.title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_info mi ON rm.title = (SELECT title FROM aka_title WHERE id = mi.movie_id)
    WHERE 
        rm.rank = 1
    GROUP BY 
        rm.title, rm.production_year, mi.info
)
SELECT 
    md.title,
    md.production_year,
    md.movie_info,
    md.company_count,
    md.company_names
FROM 
    MovieDetails md
WHERE 
    md.company_count > 0
ORDER BY 
    md.production_year DESC, 
    md.title ASC
OFFSET 5 ROWS 
FETCH NEXT 10 ROWS ONLY;
