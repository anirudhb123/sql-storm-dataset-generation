WITH MovieDetails AS (
    SELECT 
        t.title, 
        t.production_year, 
        GROUP_CONCAT(DISTINCT c.name) AS cast_names,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    WHERE 
        t.production_year IS NOT NULL
        AND (cn.country_code IS NOT NULL OR ci.note IS NOT NULL)
    GROUP BY 
        t.id
),
RankedMovies AS (
    SELECT 
        title, 
        production_year, 
        cast_names, 
        keyword_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_names,
    rm.keyword_count,
    CASE 
        WHEN rm.rank <= 5 THEN 'Top 5'
        WHEN rm.rank <= 10 THEN 'Next 5'
        ELSE 'Others'
    END AS rank_category
FROM 
    RankedMovies rm
WHERE 
    rm.production_year BETWEEN 2000 AND 2020
ORDER BY 
    rm.production_year DESC, 
    rm.keyword_count DESC;
