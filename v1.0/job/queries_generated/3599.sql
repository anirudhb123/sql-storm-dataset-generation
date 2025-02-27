WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieDetails AS (
    SELECT 
        rm.movie_id, 
        rm.title,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        ARRAY_AGG(DISTINCT cn.name) AS company_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        rm.rank <= 5
    GROUP BY 
        rm.movie_id, rm.title, mk.keyword
),
MovieInfo AS (
    SELECT 
        md.movie_id,
        md.title,
        COUNT(DISTINCT mi.id) AS info_count,
        STRING_AGG(DISTINCT mi.info, ', ') AS all_info
    FROM 
        MovieDetails md
    LEFT JOIN 
        movie_info mi ON md.movie_id = mi.movie_id
    GROUP BY 
        md.movie_id, md.title
)
SELECT 
    mi.title,
    mi.info_count,
    mi.all_info,
    md.keyword,
    COALESCE(NULLIF(md.company_names, '{}'), 'No Companies Listed') AS companies
FROM 
    MovieInfo mi
JOIN 
    MovieDetails md ON mi.movie_id = md.movie_id
WHERE 
    mi.info_count > 0 
ORDER BY 
    mi.info_count DESC, 
    md.title ASC;
