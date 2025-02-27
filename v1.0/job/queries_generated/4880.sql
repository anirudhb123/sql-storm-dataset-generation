WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
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
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        mt.title,
        GROUP_CONCAT(mk.keyword) AS keywords
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(SUM(mci.note IS NOT NULL)::integer, 0) AS has_notes_count,
    n.name AS person_name,
    n.gender,
    CASE 
        WHEN n.gender IS NULL THEN 'Not Specified'
        ELSE n.gender
    END AS gender_desc
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title = mk.title
LEFT JOIN 
    cast_info ci ON tm.production_year = ci.movie_id 
LEFT JOIN 
    aka_name n ON ci.person_id = n.person_id
LEFT JOIN 
    movie_info mi ON tm.title = mi.info 
GROUP BY 
    tm.title, tm.production_year, mk.keywords, n.name, n.gender
ORDER BY 
    tm.production_year DESC, has_notes_count DESC;
