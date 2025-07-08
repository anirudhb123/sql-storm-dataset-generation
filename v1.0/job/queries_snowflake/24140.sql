
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM
        aka_title t
    LEFT JOIN
        cast_info ci ON t.id = ci.movie_id
    WHERE
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
    GROUP BY
        t.id, t.title, t.production_year
),

FilteredMovies AS (
    SELECT
        r.movie_id,
        r.title,
        r.production_year,
        r.cast_count
    FROM
        RankedMovies r
    WHERE
        r.rn <= 5
),

MovieKeywords AS (
    SELECT 
        fm.movie_id, 
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords 
    FROM 
        FilteredMovies fm
    JOIN 
        movie_keyword mk ON fm.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        fm.movie_id
)

SELECT 
    fm.title,
    fm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(ci.cast_count, 0) AS cast_count,
    CASE 
        WHEN fm.production_year IS NULL THEN 'Unknown Year'
        WHEN fm.production_year > 2000 THEN 'Modern Era'
        ELSE 'Classic Era'
    END AS era,
    LENGTH(fm.title) AS title_length
FROM 
    FilteredMovies fm
LEFT JOIN 
    (SELECT movie_id, COUNT(person_id) AS cast_count FROM cast_info GROUP BY movie_id) ci ON fm.movie_id = ci.movie_id
LEFT JOIN 
    MovieKeywords mk ON fm.movie_id = mk.movie_id
WHERE 
    fm.production_year BETWEEN 2000 AND 2023
ORDER BY 
    fm.production_year DESC, 
    title_length DESC;
