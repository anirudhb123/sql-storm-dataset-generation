WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_order
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
), MovieDetails AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COALESCE(ci.company_name, 'Independent') AS company_name
    FROM 
        RankedMovies rm
    LEFT JOIN (
        SELECT 
            mk.movie_id,
            STRING_AGG(k.keyword, ', ') AS keywords
        FROM 
            movie_keyword mk
        INNER JOIN 
            keyword k ON mk.keyword_id = k.id
        GROUP BY 
            mk.movie_id
    ) mk ON rm.title = mk.movie_id
    LEFT JOIN (
        SELECT 
            mc.movie_id,
            STRING_AGG(cn.name, ', ') AS company_name
        FROM 
            movie_companies mc
        INNER JOIN 
            company_name cn ON mc.company_id = cn.id
        GROUP BY 
            mc.movie_id
    ) ci ON rm.title = ci.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.keywords,
    md.company_name,
    CASE 
        WHEN md.cast_count > 10 THEN 'High Profile'
        WHEN md.cast_count BETWEEN 5 AND 10 THEN 'Medium Profile'
        ELSE 'Low Profile'
    END AS profile_status
FROM 
    MovieDetails md
WHERE 
    md.rank_order <= 5
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;

