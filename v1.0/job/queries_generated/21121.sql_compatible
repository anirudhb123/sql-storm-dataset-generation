
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_within_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
DirectorsAndStars AS (
    SELECT 
        cc.movie_id,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT d.name, ', ') AS director_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        complete_cast cc ON ci.movie_id = cc.movie_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = ci.movie_id
    LEFT JOIN 
        company_name d ON mc.company_id = d.id AND mc.company_type_id = (
            SELECT id FROM company_type WHERE kind = 'Director' LIMIT 1
        )
    GROUP BY 
        cc.movie_id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(mi.info, 'No info') AS info_content,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_info mi
    JOIN 
        movie_keyword mk ON mi.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        aka_title m ON m.id = mi.movie_id
    WHERE 
        mi.note IS NULL OR mi.note != 'Discard'
    GROUP BY 
        m.id, mi.info
),
PerformanceBenchmark AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        das.cast_names,
        das.director_names,
        mi.info_content,
        mi.keyword_count,
        CASE 
            WHEN rm.rank_within_year <= 3 THEN 'Top'
            ELSE 'Others'
        END AS rank_label
    FROM 
        RankedMovies rm
    LEFT JOIN 
        DirectorsAndStars das ON rm.movie_id = das.movie_id
    LEFT JOIN 
        MovieInfo mi ON rm.movie_id = mi.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    cast_names,
    director_names,
    info_content,
    keyword_count,
    rank_label,
    COUNT(*) OVER() AS total_movies,
    MAX(keyword_count) OVER() AS max_keywords
FROM 
    PerformanceBenchmark
WHERE 
    production_year >= 2000
ORDER BY 
    production_year DESC, 
    rank_label ASC, 
    title;
