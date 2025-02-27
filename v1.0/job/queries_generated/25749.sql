WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        AKA.full_name,
        COUNT(CAST.id) AS cast_count,
        ARRAY_AGG(DISTINCT keyword.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY title.id ORDER BY COUNT(CAST.id) DESC) AS rank
    FROM title
    JOIN aka_title AS AKA ON title.id = AKA.movie_id
    JOIN cast_info AS CAST ON title.id = CAST.movie_id
    JOIN aka_name AS NAME ON CAST.person_id = NAME.person_id
    JOIN movie_keyword AS MK ON title.id = MK.movie_id
    JOIN keyword ON MK.keyword_id = keyword.id
    WHERE title.production_year BETWEEN 2000 AND 2020
    GROUP BY title.id, title.title, title.production_year, AKA.full_name
),
MovieStats AS (
    SELECT 
        RankedMovies.movie_id,
        RankedMovies.movie_title,
        RankedMovies.production_year,
        ARRAY_AGG(DISTINCT RankedMovies.full_name) AS cast_members,
        COUNT(DISTINCT keyword.keyword) AS unique_keyword_count
    FROM RankedMovies
    WHERE RankedMovies.rank <= 5 -- Top 5 ranked movies per title
    GROUP BY RankedMovies.movie_id, RankedMovies.movie_title, RankedMovies.production_year
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    cast_members,
    unique_keyword_count,
    (SELECT COUNT(*) FROM movie_info WHERE movie_id = MovieStats.movie_id) AS info_count,
    (SELECT COUNT(*) FROM movie_link WHERE movie_id = MovieStats.movie_id) AS link_count
FROM MovieStats
ORDER BY production_year DESC, unique_keyword_count DESC;
