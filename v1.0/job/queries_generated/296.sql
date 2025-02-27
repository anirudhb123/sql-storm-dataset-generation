WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        RANK() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, at.title ASC) AS rank_in_year,
        COUNT(DISTINCT ci.person_id) AS num_cast_members
    FROM 
        aka_title at
    LEFT JOIN 
        complete_cast cc ON at.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        at.id
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_in_year <= 5
),
MovieKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword mk ON mt.keyword_id = mk.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    (SELECT AVG(m_info.info::FLOAT) FROM movie_info m_info WHERE m_info.movie_id = tm.movie_id AND m_info.info_type_id IN (SELECT id FROM info_type WHERE info = 'box office')) AS average_box_office
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year
ORDER BY 
    tm.production_year DESC, cast_count DESC;
