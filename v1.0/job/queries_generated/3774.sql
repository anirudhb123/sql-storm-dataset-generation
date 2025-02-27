WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_id) OVER (PARTITION BY t.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
CompanyInfo AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        movie_info m ON mc.movie_id = m.movie_id
    WHERE 
        m.info_type_id IS NOT NULL
    GROUP BY 
        m.movie_id
),
PopularKeywords AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
    HAVING 
        COUNT(DISTINCT k.keyword) > 5
),
FinalResult AS (
    SELECT 
        rm.title,
        rm.production_year,
        coalesce(ci.company_count, 0) AS company_count,
        coalesce(ki.keyword_count, 0) AS keyword_count,
        rm.cast_count,
        rm.year_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyInfo ci ON rm.id = ci.movie_id
    LEFT JOIN 
        PopularKeywords ki ON rm.id = ki.movie_id
)
SELECT 
    title,
    production_year,
    company_count,
    keyword_count,
    cast_count,
    year_rank,
    CASE 
        WHEN year_rank <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS rank_category
FROM 
    FinalResult
WHERE 
    production_year BETWEEN 2000 AND 2020
ORDER BY 
    production_year DESC, rank_category, title;
