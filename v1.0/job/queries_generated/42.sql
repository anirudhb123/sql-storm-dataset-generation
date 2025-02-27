WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        RANK() OVER (PARTITION BY m.production_year ORDER BY LENGTH(m.title) DESC) AS rank_by_length,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    WHERE 
        m.production_year >= 2000 
        AND m.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%movie%')
    GROUP BY 
        m.id
),
TopMovies AS (
    SELECT 
        movie_id, title, rank_by_length, keyword_count, cast_count
    FROM 
        RankedMovies
    WHERE 
        rank_by_length <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.keyword_count,
        tm.cast_count,
        COALESCE(mi.info, 'No info available') AS movie_info,
        COALESCE(NULLIF(comp.name, ''), 'Unknown Company') AS company_name
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_info mi ON tm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name comp ON mc.company_id = comp.id
)
SELECT 
    md.movie_id,
    md.title,
    md.keyword_count,
    md.cast_count,
    CASE 
        WHEN md.cast_count > 10 THEN 'Popular'
        WHEN md.cast_count BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Niche'
    END AS popularity_category,
    md.movie_info
FROM 
    MovieDetails md
ORDER BY 
    md.keyword_count DESC, 
    md.cast_count DESC
LIMIT 50;
