WITH RecursiveMovieCTE AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COALESCE(mci.company_count, 0) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.id) AS movie_rank
    FROM
        aka_title mt
    LEFT JOIN (
        SELECT 
            mc.movie_id,
            COUNT(DISTINCT mc.company_id) AS company_count
        FROM
            movie_companies mc
        GROUP BY 
            mc.movie_id
    ) AS mci ON mt.id = mci.movie_id
    WHERE 
        mt.production_year IS NOT NULL
),
FormattedTitle AS (
    SELECT
        movie_id,
        movie_title,
        production_year,
        CONCAT('Title: ', movie_title, ' | Year: ', production_year) AS formatted_title
    FROM 
        RecursiveMovieCTE
    WHERE
        movie_rank <= 5 -- Only take first 5 movies per production year
),
MovieInfoWithKeywords AS (
    SELECT
        f.movie_id,
        f.formatted_title,
        k.keyword
    FROM 
        FormattedTitle f
    LEFT JOIN movie_keyword mk ON f.movie_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword IS NOT NULL
)
SELECT 
    DISTINCT f.formatted_title,
    COUNT(DISTINCT mk.movie_id) OVER (PARTITION BY mk.keyword) AS movie_count_with_keyword,
    CASE
        WHEN COUNT(mk.movie_id) > 5 THEN 'Popular'
        ELSE 'Less Popular'
    END AS popularity_category
FROM 
    FormattedTitle f
LEFT JOIN MovieInfoWithKeywords mk ON f.movie_id = mk.movie_id
LEFT JOIN aka_name an ON an.id = f.movie_id
WHERE 
    (an.name IS NOT NULL AND an.name != '')
    OR (an.name IS NULL AND f.production_year < 2000)
ORDER BY 
    f.production_year DESC, 
    movie_count_with_keyword DESC NULLS LAST;
