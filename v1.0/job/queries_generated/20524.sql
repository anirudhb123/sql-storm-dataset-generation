WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT cc.person_id) DESC) AS rank_within_year
    FROM 
        aka_title mt
    JOIN 
        complete_cast cct ON mt.id = cct.movie_id
    JOIN 
        cast_info cc ON cct.subject_id = cc.id
    LEFT JOIN 
        aka_name an ON cc.person_id = an.person_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_within_year = 1
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        string_agg(DISTINCT an.name, ', ') AS actors,
        COALESCE(mk.keyword_count, 0) AS keyword_count
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        m.id, m.title, mk.keyword_count
),
FinalOutput AS (
    SELECT 
        md.title,
        md.actors,
        md.keyword_count,
        CASE 
            WHEN md.keyword_count > 5 THEN 'High'
            WHEN md.keyword_count BETWEEN 3 AND 5 THEN 'Medium'
            ELSE 'Low' 
        END AS keyword_rating,
        COALESCE(TOP.title, 'No Top Movie') AS top_movie
    FROM 
        MovieDetails md
    LEFT JOIN 
        TopMovies TOP ON md.title = TOP.title
)
SELECT 
    movie_id,
    title,
    actors,
    keyword_count,
    keyword_rating,
    top_movie
FROM 
    FinalOutput
ORDER BY 
    keyword_count DESC, title;

-- Complicated predicates using NULL logic and expressions
SELECT 
    coalesce(m.title, 'Untitled') AS movie_title,
    max(css.status) AS latest_status,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM movie_info mi 
            WHERE mi.movie_id = m.id 
            AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
        ) THEN 'Has Box Office Info' 
        ELSE 'No Box Office Info' 
    END AS box_office_info
FROM 
    aka_title m
LEFT JOIN 
    complete_cast cc ON m.id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.id = ci.id
LEFT JOIN 
    (SELECT DISTINCT movie_id, status_id FROM complete_cast) css ON css.movie_id = m.id
GROUP BY 
    m.id
HAVING 
    COUNT(cc.id) > 3 
    AND MAX(m.production_year) > 2000
ORDER BY 
    latest_status DESC NULLS LAST;
