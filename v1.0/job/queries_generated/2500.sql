WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY c.nr_order DESC) AS rank_order,
        COUNT(DISTINCT k.keyword) OVER (PARTITION BY t.id) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year > 2000 AND 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        GROUP_CONCAT(DISTINCT mi.info, ', ') AS info_details
    FROM 
        movie_info m
    JOIN 
        info_type it ON m.info_type_id = it.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.title_id,
    rm.title,
    rm.production_year,
    rm.rank_order,
    COALESCE(mi.info_details, 'No info available') AS additional_info,
    rm.keyword_count,
    COUNT(DISTINCT cc.id) AS total_cast
FROM 
    RankedMovies rm
LEFT JOIN 
    complete_cast cc ON rm.title_id = cc.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.title_id = mi.movie_id
WHERE 
    rm.rank_order <= 5
GROUP BY 
    rm.title_id, rm.title, rm.production_year, rm.rank_order, mi.info_details
ORDER BY 
    rm.production_year DESC, rm.rank_order;
