WITH RankedMovies AS (
    SELECT 
        title.title AS movie_title,
        aka.title AS aka_title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.title) AS rn
    FROM 
        title
    LEFT JOIN 
        aka_title aka ON title.id = aka.movie_id
),

MovieStats AS (
    SELECT 
        movie_title,
        aka_title,
        production_year,
        COUNT(DISTINCT mi.note) AS info_count,
        SUM(
            CASE 
                WHEN mi.note IS NOT NULL AND mi.info IS NOT NULL THEN LENGTH(mi.info) 
                ELSE 0 
            END
        ) AS total_info_length
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mi ON rm.movie_title = mi.info
    GROUP BY 
        movie_title, aka_title, production_year
),

CastSummary AS (
    SELECT 
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(CASE WHEN ci.note IS NOT NULL THEN ci.nr_order ELSE NULL END) AS avg_order
    FROM 
        cast_info ci
    JOIN 
        title t ON ci.movie_id = t.id
    WHERE 
        t.production_year > 2000
),

TitleKeyword AS (
    SELECT 
        m.title AS movie_title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.title
)

SELECT 
    ms.movie_title,
    ms.aka_title,
    ms.production_year,
    ms.info_count,
    ms.total_info_length,
    cs.total_cast,
    cs.avg_order,
    tk.keywords
FROM 
    MovieStats ms
LEFT JOIN 
    CastSummary cs ON ms.movie_title = cs.total_cast
LEFT JOIN 
    TitleKeyword tk ON ms.movie_title = tk.movie_title
WHERE 
    ms.production_year IS NOT NULL
    AND (ms.info_count > 0 OR cs.total_cast IS NULL)
ORDER BY 
    COALESCE(ms.production_year, 0) DESC,
    ms.info_count DESC,
    ms.movie_title;
