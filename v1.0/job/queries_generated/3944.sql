WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY b.nr_order) AS rank_order 
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info b ON a.id = b.movie_id
    WHERE 
        a.production_year IS NOT NULL
),
CompanyDetails AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name, 
        ct.kind AS company_type,
        COUNT(*) AS num_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
),
TitleKeyword AS (
    SELECT 
        mt.movie_id, 
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword mk ON mt.keyword_id = mk.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    rm.production_year, 
    rm.title, 
    cd.company_name, 
    cd.company_type,
    tk.keywords,
    (SELECT COUNT(*) 
     FROM complete_cast cc 
     WHERE cc.movie_id = rm.id) AS total_cast,
    CASE 
        WHEN rm.rank_order <= 5 THEN 'Top 5'
        ELSE 'Below Top 5'
    END AS rank_category
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.id = cd.movie_id
LEFT JOIN 
    TitleKeyword tk ON rm.id = tk.movie_id
WHERE 
    rm.rank_order < 10
AND 
    (cd.company_name IS NOT NULL OR tk.keywords IS NOT NULL)
ORDER BY 
    rm.production_year DESC, rm.rank_order;
