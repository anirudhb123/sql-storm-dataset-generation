WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC, m.title ASC) AS rank,
        COUNT(*) OVER (PARTITION BY m.production_year) AS total_movies
    FROM
        aka_title m
    WHERE
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
TopMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.rank,
        rm.total_movies,
        COALESCE(STRING_AGG(DISTINCT k.keyword, ', '), 'No Keywords') AS keywords
    FROM
        RankedMovies rm
        LEFT JOIN movie_keyword mk ON rm.movie_id = mk.movie_id
        LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE
        rm.rank <= 5
    GROUP BY
        rm.movie_id, rm.title, rm.production_year, rm.rank, rm.total_movies
),
CastSummary AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        STRING_AGG(DISTINCT CONCAT(a.name, '(', rt.role, ')'), ', ') AS cast_details
    FROM
        cast_info c
        JOIN aka_name a ON c.person_id = a.person_id
        JOIN role_type rt ON c.role_id = rt.id
    GROUP BY
        c.movie_id
),
MovieStatistics AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.keywords,
        COALESCE(cs.num_cast_members, 0) AS total_cast,
        CASE 
            WHEN tm.total_movies >= 5 THEN 'Popular Year'
            WHEN tm.rank = 1 THEN 'Top Movie'
            ELSE 'Regular Movie'
        END AS movie_type
    FROM 
        TopMovies tm
        LEFT JOIN CastSummary cs ON tm.movie_id = cs.movie_id
)
SELECT
    ms.title,
    ms.production_year,
    ms.total_cast,
    ms.keywords,
    ms.movie_type,
    CASE 
        WHEN ms.total_cast = 0 THEN 'No Cast Available' 
        ELSE 'Cast Present'
    END AS cast_status
FROM
    MovieStatistics ms
ORDER BY
    ms.production_year DESC,
    ms.total_cast DESC,
    ms.title ASC;
