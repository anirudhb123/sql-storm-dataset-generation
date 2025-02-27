WITH RankedMovies AS (
    SELECT
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM
        aka_title at
    LEFT JOIN
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY
        at.title, at.production_year
),
HighCountMovies AS (
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
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
MovieDetails AS (
    SELECT
        hcm.title,
        hcm.production_year,
        COALESCE(mk.keywords, 'No keywords') AS keywords
    FROM
        HighCountMovies hcm
    LEFT JOIN
        MovieKeywords mk ON hcm.title = (SELECT at.title FROM aka_title at WHERE at.movie_id = mk.movie_id)
)
SELECT
    md.title,
    md.production_year,
    md.keywords,
    CASE 
        WHEN md.keywords IS NULL THEN 'No keywords found'
        ELSE 'Keywords exist'
    END AS keyword_status
FROM
    MovieDetails md
ORDER BY
    md.production_year DESC,
    md.title;
