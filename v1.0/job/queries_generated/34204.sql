WITH RECURSIVE MovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        cte.level + 1
    FROM 
        aka_title t
    JOIN MovieCTE cte ON t.episode_of_id = cte.movie_id
),

CastDetails AS (
    SELECT 
        c.movie_id,
        GROUP_CONCAT(DISTINCT a.name) AS cast_names,
        COUNT(c.person_id) AS cast_count
    FROM 
        cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),

CompanyInfo AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        COUNT(DISTINCT mc.company_id) AS num_companies
    FROM 
        movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),

KeywordInfo AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    cd.cast_names,
    cd.cast_count,
    ci.companies,
    ci.num_companies,
    ki.keywords,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank,
    (CASE 
        WHEN cd.cast_count > 5 THEN 'Large Cast'
        WHEN cd.cast_count BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast' 
    END) AS cast_size_category
FROM 
    MovieCTE m
LEFT JOIN CastDetails cd ON m.movie_id = cd.movie_id
LEFT JOIN CompanyInfo ci ON m.movie_id = ci.movie_id
LEFT JOIN KeywordInfo ki ON m.movie_id = ki.movie_id
WHERE 
    m.production_year IS NOT NULL
ORDER BY 
    m.production_year DESC, m.title;

