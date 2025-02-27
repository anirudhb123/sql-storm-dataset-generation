WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY t.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') OVER (PARTITION BY t.id) AS actors,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year IS NOT NULL
        AND ak.name IS NOT NULL
),
NullCheck AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        actors,
        rank,
        CASE 
            WHEN production_year < 2000 THEN 'Classic'
            WHEN production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Contemporary'
        END AS era
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)
SELECT 
    n.movie_id,
    n.title,
    n.production_year,
    n.era,
    n.cast_count,
    n.actors,
    COALESCE(SUM(mk.keyword_id), 0) AS keyword_count,
    COALESCE(MAX(mi.info), 'No info') AS additional_info
FROM 
    NullCheck n
LEFT JOIN 
    movie_keyword mk ON n.movie_id = mk.movie_id
LEFT JOIN 
    movie_info mi ON n.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'description')
GROUP BY 
    n.movie_id, n.title, n.production_year, n.era, n.cast_count, n.actors
ORDER BY 
    n.rank;
