WITH YearlyMovies AS (
    SELECT
        at.production_year,
        COUNT(*) AS movie_count,
        STRING_AGG(at.title, ', ') AS titles
    FROM
        aka_title at
    WHERE
        at.production_year IS NOT NULL
    GROUP BY
        at.production_year
),
RankedMovies AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY movie_count DESC) AS rank
    FROM
        YearlyMovies
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(aka.name, ', ') AS cast_names
    FROM
        cast_info ci
    JOIN
        aka_name aka ON ci.person_id = aka.person_id
    GROUP BY
        ci.movie_id
),
MovieGenres AS (
    SELECT
        at.id AS movie_id,
        kt.kind AS genre
    FROM
        aka_title at
    INNER JOIN
        kind_type kt ON at.kind_id = kt.id
)
SELECT 
    rm.production_year,
    rm.movie_count,
    rm.titles,
    COALESCE(cd.cast_count, 0) AS total_cast,
    COALESCE(cd.cast_names, 'No Cast') AS cast_details,
    STRING_AGG(mg.genre, ', ') AS genres
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.production_year = (SELECT production_year FROM aka_title WHERE id = cd.movie_id)
LEFT JOIN 
    MovieGenres mg ON mg.movie_id IN (SELECT movie_id FROM cast_info WHERE movie_id = cd.movie_id)
WHERE 
    rm.rank <= 10
GROUP BY 
    rm.production_year, rm.movie_count, rm.titles, cd.cast_count, cd.cast_names
ORDER BY 
    rm.production_year DESC;
