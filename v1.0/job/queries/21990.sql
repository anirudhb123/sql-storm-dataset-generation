
WITH Movie_Stats AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        MAX(ci.nr_order) AS max_cast_order,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(CASE WHEN mt.production_year IS NOT NULL THEN EXTRACT(YEAR FROM DATE '2024-10-01') - mt.production_year ELSE NULL END) AS age_of_movie
    FROM
        aka_title mt
    LEFT JOIN
        cast_info ci ON ci.movie_id = mt.id
    GROUP BY
        mt.id, mt.title
), 
Title_Keywords AS (
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
Company_Data AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id
)
SELECT 
    ms.title,
    ks.keywords,
    cd.companies,
    cd.company_types,
    ms.total_cast,
    ms.max_cast_order,
    ms.age_of_movie,
    CASE 
        WHEN ms.total_cast > 10 THEN 'Large Cast'
        WHEN ms.total_cast <= 10 AND ms.total_cast > 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    CASE 
        WHEN cd.companies IS NULL THEN 'No companies associated'
        ELSE 'Companies exist'
    END AS company_association,
    CASE 
        WHEN ms.age_of_movie > 20 THEN 'Classic'
        ELSE 'Modern'
    END AS movie_age_category
FROM
    Movie_Stats ms
LEFT JOIN
    Title_Keywords ks ON ms.movie_id = ks.movie_id
LEFT JOIN
    Company_Data cd ON ms.movie_id = cd.movie_id
WHERE 
    ms.age_of_movie IS NOT NULL
    AND ms.total_cast > 0
    AND (EXISTS (SELECT 1 FROM cast_info ci WHERE ci.movie_id = ms.movie_id AND ci.note IS NOT NULL)
         OR (cd.companies IS NOT NULL AND cd.company_types IS NOT NULL))
ORDER BY
    ms.age_of_movie DESC,
    ms.total_cast DESC
LIMIT 100;
