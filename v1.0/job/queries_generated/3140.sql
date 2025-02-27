WITH MovieDetails AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        STRING_AGG(DISTINCT ac.name, ', ') AS cast_names,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    LEFT JOIN 
        aka_name ac ON ci.person_id = ac.person_id
    LEFT JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year
),
HighRatedMovies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.cast_names,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.keyword_count DESC) AS rank
    FROM 
        MovieDetails md
    WHERE 
        md.keyword_count > 5
),
WorstMovies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.cast_names,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.keyword_count ASC) AS rank
    FROM 
        MovieDetails md
    WHERE 
        md.keyword_count < 3
),
CombinedResults AS (
    SELECT 
        movie_title,
        production_year,
        cast_names,
        rank,
        'High Rated' AS category
    FROM 
        HighRatedMovies
    UNION ALL
    SELECT 
        movie_title,
        production_year,
        cast_names,
        rank,
        'Worst Rated' AS category
    FROM 
        WorstMovies
)
SELECT 
    cr.movie_title,
    cr.production_year,
    cr.cast_names,
    cr.rank,
    cr.category
FROM 
    CombinedResults cr
WHERE 
    (cr.category = 'High Rated' AND cr.rank <= 3)
    OR 
    (cr.category = 'Worst Rated' AND cr.rank <= 3)
ORDER BY 
    cr.production_year DESC, 
    cr.category, 
    cr.rank;
