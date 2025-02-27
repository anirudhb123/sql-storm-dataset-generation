WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
),
CastCounts AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS cast_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(cc.cast_count, 0) AS cast_count,
        CASE 
            WHEN m.production_year < 2000 THEN 'Classic'
            WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS era
    FROM 
        RankedMovies m
    LEFT JOIN 
        CastCounts cc ON m.movie_id = cc.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.era,
    (
        SELECT 
            COUNT(DISTINCT k.keyword)
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        WHERE 
            mk.movie_id = md.movie_id
    ) AS keyword_count,
    (
        SELECT 
            string_agg(DISTINCT ak.name, ', ') 
        FROM 
            aka_name ak
        JOIN 
            cast_info ci ON ak.person_id = ci.person_id
        WHERE 
            ci.movie_id = md.movie_id
    ) AS actors_names
FROM 
    MovieDetails md
WHERE 
    md.cast_count > 0
AND 
    md.production_year IS NOT NULL
ORDER BY 
    md.production_year DESC, md.title ASC
LIMIT 50;
