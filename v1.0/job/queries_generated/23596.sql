WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(CAST(mk.id AS INTEGER)) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(mk.id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN movie_keyword mk ON a.id = mk.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        movie_title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
AllMovieInfo AS (
    SELECT 
        tm.movie_title,
        tm.production_year,
        COALESCE(mi.info, 'No info available') AS additional_info,
        CASE 
            WHEN ci.note IS NOT NULL THEN 'Has notes'
            ELSE 'No notes'
        END AS note_status,
        ARRAY_AGG(DISTINCT c.name) FILTER (WHERE c.name IS NOT NULL) AS cast_names
    FROM 
        TopMovies tm 
    LEFT JOIN movie_info mi ON tm.movie_title = mi.info 
    LEFT JOIN complete_cast cc ON cc.movie_id = (SELECT id FROM aka_title WHERE title = tm.movie_title LIMIT 1)
    LEFT JOIN cast_info ci ON ci.movie_id = cc.movie_id
    LEFT JOIN aka_name c ON c.person_id = ci.person_id
    GROUP BY 
        tm.movie_title, tm.production_year, mi.info
),
FinalResults AS (
    SELECT 
        ami.movie_title,
        ami.production_year,
        ami.additional_info,
        ami.note_status,
        ami.cast_names,
        CASE 
            WHEN ami.note_status = 'Has notes' THEN 'Evaluate further'
            ELSE NULL
        END AS further_evaluation
    FROM 
        AllMovieInfo ami
)
SELECT 
    *,
    CASE 
        WHEN length(ami.movie_title) > 20 THEN 'Long Title'
        ELSE 'Short Title'
    END AS title_length_category
FROM 
    FinalResults ami
WHERE 
    ami.additional_info NOT LIKE '%incomplete%'
    AND ami.cast_names IS NOT NULL
ORDER BY 
    ami.production_year DESC, 
    ami.movie_title ASC;
