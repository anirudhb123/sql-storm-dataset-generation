WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY m.production_year DESC) AS rank_by_year
    FROM 
        aka_title a
    JOIN 
        movie_keyword k ON a.id = k.movie_id
    JOIN 
        keyword w ON k.keyword_id = w.id
    JOIN 
        movie_info mi ON a.id = mi.movie_id
    JOIN 
        info_type it ON mi.info_type_id = it.id
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        title t ON a.id = t.imdb_id
    WHERE
        a.production_year BETWEEN 2000 AND 2020
        AND it.info LIKE '%box office%'
        AND (w.keyword LIKE '%comedy%' OR w.keyword LIKE '%drama%')
),
CompanyCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
FinalResults AS (
    SELECT 
        rm.title,
        rm.production_year,
        cc.company_count,
        COALESCE(NULLIF(it.info, ''), 'No Info') AS info_status
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyCount cc ON rm.id = cc.movie_id
    LEFT JOIN 
        movie_info mi ON rm.id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        cc.company_count IS NOT NULL
        OR rm.rank_by_year <= 5
)
SELECT 
    title,
    production_year,
    company_count,
    info_status
FROM 
    FinalResults
WHERE 
    company_count > 1
ORDER BY 
    production_year DESC, title;
