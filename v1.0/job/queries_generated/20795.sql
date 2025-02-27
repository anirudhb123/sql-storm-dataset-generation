WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        RANK() OVER (PARTITION BY title.production_year ORDER BY title.title) AS rank_per_year
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(MAX(ci.nr_order), 0) AS max_cast_order,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        RankedMovies m
    LEFT JOIN 
        complete_cast cc ON m.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.movie_id
    GROUP BY 
        m.movie_id, m.title, m.production_year
),
HighlightedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.max_cast_order,
        md.keyword_count,
        CASE 
            WHEN md.max_cast_order > 5 THEN 'High'
            WHEN md.keyword_count > 10 THEN 'Keyword Rich'
            ELSE 'Normal'
        END AS movie_category
    FROM 
        MovieDetails md
    WHERE 
        md.max_cast_order IS NOT NULL AND
        md.keyword_count > 0
),
RecentMovies AS (
    SELECT 
        hm.movie_id,
        hm.title,
        hm.movie_category,
        hm.production_year,
        ROW_NUMBER() OVER (PARTITION BY hm.movie_category ORDER BY hm.production_year DESC) AS category_rank
    FROM 
        HighlightedMovies hm
    WHERE 
        hm.production_year >= (SELECT MAX(production_year) - 10 FROM title)
)
SELECT 
    rm.rank_per_year,
    rm.title,
    COALESCE(rm.production_year, 'Unknown') AS production_year,
    hm.movie_category,
    hm.category_rank
FROM 
    RankedMovies rm
LEFT JOIN 
    RecentMovies hm ON rm.movie_id = hm.movie_id
ORDER BY 
    rm.rank_per_year DESC, 
    hm.movie_category, 
    hm.category_rank;
