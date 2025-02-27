WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code IS NOT NULL
),
MovieDetails AS (
    SELECT 
        rm.title,
        rm.production_year,
        COALESCE(SUM(mi.info ILIKE '%award%') FILTER (WHERE mi.info_type_id = 1), 0) AS award_count,
        COALESCE(AVG(ti.kind_id), 0) AS avg_kind_id,
        row_number() OVER (ORDER BY rm.production_year DESC) AS rn
    FROM 
        RankedMovies rm
    LEFT JOIN 
        complete_cast cc ON rm.title_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_info mi ON rm.title_id = mi.movie_id
    LEFT JOIN 
        kind_type ti ON rm.title_id = ti.id
    GROUP BY 
        rm.title, rm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.award_count,
    md.avg_kind_id,
    CASE 
        WHEN md.cast_count > 10 THEN 'Large Cast'
        WHEN md.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    NULLIF((SELECT AVG(cast_count) FROM RankedMovies), 0) AS avg_overall_cast_count
FROM 
    MovieDetails md
WHERE 
    md.production_year > 2000
ORDER BY 
    md.production_year DESC, md.cast_count DESC
LIMIT 100;
