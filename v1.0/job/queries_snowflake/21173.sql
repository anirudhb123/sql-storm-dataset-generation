
WITH RecursiveTitleInfo AS (
    SELECT 
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),
MovieRating AS (
    SELECT 
        m.id AS movie_id,
        COUNT(c.id) AS cast_count,
        SUM(CASE WHEN c.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS ordered_cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id
),
AnnotatedMovies AS (
    SELECT 
        rti.title_id,
        rti.movie_title,
        rti.production_year,
        rti.movie_keyword,
        COALESCE(CAST(mr.cast_count AS FLOAT) / NULLIF(mr.ordered_cast_count, 0), 0) AS cast_ratio,
        rti.keyword_rank
    FROM 
        RecursiveTitleInfo rti
    JOIN 
        MovieRating mr ON rti.title_id = mr.movie_id
),
DistinctMovieKeywords AS (
    SELECT 
        movie_title,
        LISTAGG(movie_keyword, ', ') WITHIN GROUP (ORDER BY movie_keyword) AS all_keywords
    FROM 
        AnnotatedMovies
    WHERE
        keyword_rank <= 5
    GROUP BY 
        movie_title
)
SELECT 
    am.movie_title,
    am.production_year,
    am.cast_ratio,
    COALESCE(dmk.all_keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN am.cast_ratio > 1 THEN 'Overloaded Cast'
        WHEN am.cast_ratio = 1 THEN 'Balanced Cast'
        ELSE 'Underloaded Cast'
    END AS cast_status
FROM 
    AnnotatedMovies am
LEFT JOIN 
    DistinctMovieKeywords dmk ON am.movie_title = dmk.movie_title
WHERE 
    am.production_year > 2000
ORDER BY 
    am.production_year DESC,
    am.cast_ratio DESC,
    am.movie_title;
