WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT
        rm.title,
        rm.production_year,
        rm.cast_count,
        rn.rank_by_cast
    FROM
        RankedMovies rm
    WHERE
        rm.rank_by_cast <= 5
),
DetailedMovieInfo AS (
    SELECT 
        tm.title,
        tm.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        COUNT(DISTINCT mc.company_id) AS production_company_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info c ON tm.title = (SELECT title FROM aka_title WHERE id = c.movie_id)
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.title)
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id 
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = tm.title)
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    dmi.title,
    dmi.production_year,
    dmi.actor_names,
    dmi.keywords,
    dmi.production_company_count,
    COALESCE(dmi.production_company_count, 0) AS company_count_with_fallback
FROM 
    DetailedMovieInfo dmi
ORDER BY 
    dmi.production_year DESC, 
    dmi.cast_count DESC;
