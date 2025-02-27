WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(DISTINCT k.keyword) OVER (PARTITION BY t.id) AS keyword_count
    FROM 
        aka_title t 
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
        AND t.title IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.* 
    FROM 
        RankedMovies rm
    WHERE 
        rm.title_rank <= 10 
        OR EXISTS (
            SELECT 1 
            FROM movie_info mi
            WHERE mi.movie_id = rm.movie_id AND mi.info_type_id = 1 
            HAVING COUNT(*) > 0
        )
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(ci.person_role_id, 'Unknown') AS role,
        cn.name AS company_name,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast cc ON tm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.movie_id
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        tm.title, tm.production_year, role, company_name
)
SELECT 
    * 
FROM 
    MovieDetails
WHERE 
    (production_year BETWEEN 2000 AND 2023 OR role = 'Director') 
    AND (company_name IS NOT NULL OR cast_count > 5)
ORDER BY 
    keyword_count DESC, production_year DESC;

-- Additional complexity: Including another layer of filtering with NULL checks and string concatenation
UNION ALL

SELECT 
    CONCAT('Movie Title: ', md.title) AS movie_title,
    md.production_year,
    md.role,
    CONCAT('Produced by: ', COALESCE(md.company_name, 'N/A')) AS production_info,
    md.cast_count
FROM 
    MovieDetails md
WHERE 
    md.cast_count IS NOT NULL
    AND (md.role IS NULL OR LENGTH(md.role) < 5)
ORDER BY 
    production_year, movie_title;
This SQL query incorporates various advanced SQL features including CTEs (Common Table Expressions), outer joins, correlated subqueries, window functions, string concatenation, and NULL handling — all while targeting interesting data from the provided schema. It aims to rank movies, filter based on roles, count distinct casts, and also includes additional complexities through a UNION ALL.
