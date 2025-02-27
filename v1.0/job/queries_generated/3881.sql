WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank_per_year,
        c.note AS cast_note,
        mc.company_id,
        COUNT(DISTINCT mkw.keyword_id) AS keyword_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mkw ON a.id = mkw.movie_id
    WHERE 
        a.production_year IS NOT NULL
        AND a.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        a.id, a.title, a.production_year, c.note, mc.company_id
),
MovieDetails AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.rank_per_year,
        COALESCE(ci.role_id, 0) AS role_id,
        ci.note AS cast_note,
        ct.kind AS company_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        complete_cast cc ON rm.company_id = cc.movie_id
    LEFT JOIN 
        company_type ct ON cc.movie_id = ct.id
    LEFT JOIN 
        cast_info ci ON rm.title = ci.note
)
SELECT 
    md.title,
    md.production_year,
    md.rank_per_year,
    md.cast_note,
    CASE 
        WHEN md.role_id IS NULL THEN 'No Role' 
        ELSE (SELECT r.role FROM role_type r WHERE r.id = md.role_id)
    END AS role_description,
    md.company_type,
    (SELECT STRING_AGG(kw.keyword, ', ') 
     FROM movie_keyword mk 
     JOIN keyword kw ON mk.keyword_id = kw.id 
     WHERE mk.movie_id = md.title) AS keywords,
    AVG(COALESCE(ri.info_type_id, 0)) AS avg_info_index
FROM 
    MovieDetails md
LEFT JOIN 
    movie_info_idx ri ON md.title = ri.info
GROUP BY 
    md.title, md.production_year, md.rank_per_year, md.cast_note, md.role_id, md.company_type
ORDER BY 
    md.production_year, md.rank_per_year DESC;
