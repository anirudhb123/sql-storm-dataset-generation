
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(SUM(c.nr_order), 0) AS total_cast,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id 
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    GROUP BY 
        t.id, t.title, t.production_year
),
DetailedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.total_cast,
        md.keyword_count,
        ROW_NUMBER() OVER (ORDER BY md.production_year DESC, md.total_cast DESC) AS rank
    FROM 
        MovieDetails md
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    dm.title,
    dm.production_year,
    dm.total_cast,
    dm.keyword_count,
    COALESCE(ci.company_count, 0) AS company_count,
    COALESCE(ci.company_names, 'No Companies') AS company_names,
    dm.rank
FROM 
    DetailedMovies dm
LEFT JOIN 
    CompanyInfo ci ON dm.movie_id = ci.movie_id
WHERE 
    (dm.total_cast > 5 OR ci.company_count IS NULL)
ORDER BY 
    dm.rank
LIMIT 50;
