
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COUNT(mc.movie_id) AS total_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) AS has_tagged_info,
        MAX(CASE WHEN k.keyword IS NOT NULL THEN k.keyword ELSE 'No keyword' END) AS keyword_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        rm.rank <= 5
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.total_companies,
    md.companies,
    md.has_tagged_info,
    COALESCE(md.keyword_info, 'N/A') AS keyword_info
FROM 
    MovieDetails md
WHERE 
    md.total_companies > 0
ORDER BY 
    md.production_year DESC, md.total_companies DESC;
