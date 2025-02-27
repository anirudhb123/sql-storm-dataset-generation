WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS cast_count,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS actors_list
    FROM title
    JOIN cast_info ON title.id = cast_info.movie_id
    JOIN aka_name ON cast_info.person_id = aka_name.person_id
    WHERE title.production_year >= 2000
    GROUP BY title.id
    ORDER BY cast_count DESC
    LIMIT 10
),
MoviesWithGenres AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.actors_list,
        STRING_AGG(DISTINCT keyword.keyword, ', ') AS keywords
    FROM RankedMovies rm
    JOIN movie_keyword mk ON rm.movie_id = mk.movie_id
    JOIN keyword ON mk.keyword_id = keyword.id
    GROUP BY rm.movie_id, rm.title, rm.production_year, rm.cast_count, rm.actors_list
),
TopMovies AS (
    SELECT 
        mwg.movie_id,
        mwg.title,
        mwg.production_year,
        mwg.cast_count,
        mwg.actors_list,
        mwg.keywords,
        company_name.name AS production_company
    FROM MoviesWithGenres mwg
    LEFT JOIN movie_companies mc ON mwg.movie_id = mc.movie_id
    LEFT JOIN company_name ON mc.company_id = company_name.id
    WHERE company_name.country_code = 'USA' OR company_name.country_code IS NULL
)
SELECT 
    movie_id,
    title,
    production_year,
    cast_count,
    actors_list,
    keywords,
    STRING_AGG(DISTINCT production_company, ', ') AS production_companies
FROM TopMovies
GROUP BY movie_id, title, production_year, cast_count, actors_list
ORDER BY production_year DESC;
