
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.id, t.title, t.production_year
),

TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),

MovieCompanies AS (
    SELECT
        t.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.id) AS num_movies_by_company
    FROM
        movie_companies mc
    JOIN 
        aka_title t ON mc.movie_id = t.id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        t.movie_id, cn.name, ct.kind
),

MoviesWithCompanies AS (
    SELECT
        tm.movie_id,
        tm.title,
        tm.production_year,
        COALESCE(SUM(CASE WHEN mc.num_movies_by_company > 1 THEN mc.num_movies_by_company ELSE 0 END), 0) AS multi_movie_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieCompanies mc ON tm.movie_id = mc.movie_id
    GROUP BY
        tm.movie_id, tm.title, tm.production_year
)

SELECT
    mwc.title,
    mwc.production_year,
    mwc.multi_movie_count,
    CASE 
        WHEN mwc.multi_movie_count > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS has_multiple_movies_by_company,
    COALESCE(COUNT(DISTINCT ak.id), 0) AS actors_appeared_in_other_movies,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors_names
FROM 
    MoviesWithCompanies mwc
LEFT JOIN 
    cast_info ci ON mwc.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE
    ak.name IS NOT NULL AND ak.name <> ''
GROUP BY 
    mwc.title, mwc.production_year, mwc.multi_movie_count
HAVING 
    mwc.production_year BETWEEN 2000 AND 2020 
    AND CASE 
        WHEN mwc.multi_movie_count > 0 THEN 'Yes' 
        ELSE 'No' 
    END = 'Yes'
ORDER BY 
    mwc.production_year DESC, mwc.multi_movie_count DESC;
