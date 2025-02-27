WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title AS movie_title, 
        t.production_year, 
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM title t
    JOIN cast_info ci ON t.id = ci.movie_id
    GROUP BY t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id, 
        rm.movie_title, 
        rm.production_year, 
        rm.cast_count
    FROM RankedMovies rm
    WHERE rm.rank <= 3
),
MovieDetails AS (
    SELECT 
        tm.movie_id, 
        tm.movie_title, 
        tm.production_year, 
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
    FROM TopMovies tm
    LEFT JOIN aka_title ak ON tm.movie_id = ak.movie_id
    LEFT JOIN movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY tm.movie_id, tm.movie_title, tm.production_year
)
SELECT 
    md.movie_id, 
    md.movie_title, 
    md.production_year, 
    md.aka_names, 
    md.company_names, 
    md.keywords
FROM MovieDetails md
ORDER BY md.production_year DESC, md.cast_count DESC;
