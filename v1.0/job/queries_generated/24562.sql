WITH RecursiveTitle AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY pg2.name ORDER BY t.production_year DESC) AS row_num,
        c1.name AS director_name,
        t.kind_id
    FROM
        title t
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_name c1 ON mc.company_id = c1.id AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Director')
    LEFT JOIN
        title tt ON tt.id = t.episode_of_id
    JOIN
        aka_title at ON at.id = t.id
    JOIN
        aka_name an ON an.id = at.id
    WHERE
        t.production_year > 2000
        AND (t.kind_id IS NULL OR t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'Fiction%'))
    ORDER BY
        t.production_year DESC
),
GenreCount AS (
    SELECT
        t.title_id,
        COUNT(DISTINCT mk.keyword_id) AS genre_count
    FROM
        RecursiveTitle rt
    LEFT JOIN
        movie_keyword mk ON mk.movie_id = rt.title_id
    GROUP BY
        t.title_id
),
TitleSummary AS (
    SELECT
        rt.title,
        rt.production_year,
        rt.director_name,
        COALESCE(gc.genre_count, 0) AS genre_count,
        CASE
            WHEN rt.kind_id IS NULL THEN 'Unknown'
            ELSE (SELECT kt.kind FROM kind_type kt WHERE kt.id = rt.kind_id LIMIT 1)
        END AS kind
    FROM
        RecursiveTitle rt
    LEFT JOIN
        GenreCount gc ON rt.title_id = gc.title_id
)
SELECT
    ts.title AS movie_title,
    ts.production_year,
    ts.director_name,
    ts.kind,
    CASE 
        WHEN ts.genre_count > 5 THEN 'Popular'
        ELSE 'Niche'
    END AS category,
    COALESCE((SELECT STRING_AGG(DISTINCT kw.keyword, ', ') 
              FROM movie_keyword mk
              JOIN keyword kw ON mk.keyword_id = kw.id
              WHERE mk.movie_id = ts.title_id), 'No keywords') AS keywords
FROM
    TitleSummary ts
WHERE
    ts.production_year >= (SELECT MAX(production_year) FROM title WHERE production_year < 2000)
ORDER BY
    ts.production_year DESC,
    ts.category,
    ts.title;
