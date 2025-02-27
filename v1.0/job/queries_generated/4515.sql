WITH RankedMovies AS (
    SELECT 
        title.title AS movie_title,
        aka_name.name AS person_name,
        ROW_NUMBER() OVER(PARTITION BY title.id ORDER BY person_info.info DESC NULLS LAST) AS rank
    FROM 
        title
    INNER JOIN 
        complete_cast ON title.id = complete_cast.movie_id
    LEFT JOIN 
        cast_info ON complete_cast.subject_id = cast_info.id
    LEFT JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    LEFT JOIN 
        person_info ON aka_name.person_id = person_info.person_id
    WHERE 
        title.production_year > 2000 
        AND (person_info.info_type_id = (SELECT id FROM info_type WHERE info = 'bio') OR person_info.info IS NULL)
),
GenreCount AS (
    SELECT 
        title.id AS movie_id,
        COUNT(DISTINCT keyword.keyword) AS genre_count
    FROM 
        title
    JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        title.id
)
SELECT 
    R.movie_title,
    R.person_name,
    G.genre_count,
    CASE
        WHEN G.genre_count > 5 THEN 'Diverse Genre'
        ELSE 'Limited Genre'
    END AS genre_diversity,
    COALESCE(NULLIF(SUM(case when R.rank = 1 THEN 1 ELSE 0 END), 0), 'No Lead') AS lead_count
FROM 
    RankedMovies R
JOIN 
    GenreCount G ON R.movie_title = G.movie_id
GROUP BY 
    R.movie_title, R.person_name, G.genre_count
HAVING 
    COUNT(R.person_name) > 1
ORDER BY 
    G.genre_count DESC, R.movie_title;
