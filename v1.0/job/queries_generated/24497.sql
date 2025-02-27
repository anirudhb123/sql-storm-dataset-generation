WITH RecursiveMovieCTE AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.production_year DESC) AS row_num
    FROM title
    WHERE title.production_year IS NOT NULL
),

CastDetails AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN role_type rt ON ci.role_id = rt.id
),

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)

SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    cd.actor_name,
    cd.role_name,
    CASE
        WHEN cd.actor_order = 1 THEN 'Lead'
        WHEN cd.actor_order <= 3 THEN 'Supporting'
        ELSE 'Minor'
    END AS role_category,
    COALESCE(mk.keywords, 'No keywords') AS movie_keywords
FROM RecursiveMovieCTE m
LEFT JOIN CastDetails cd ON m.movie_id = cd.movie_id
LEFT JOIN MovieKeywords mk ON m.movie_id = mk.movie_id
WHERE 
    (m.production_year >= 2000 AND m.production_year < 2023) OR 
    (m.production_year IS NULL)
ORDER BY 
    m.production_year DESC, 
    cd.actor_order
LIMIT 100;

-- Include a bizarre edge case that attempts to find titles with null or space names, utilizing obscure SQL semantics.
WITH NullAndSpaceMovies AS (
    SELECT 
        id,
        title,
        CASE 
            WHEN TRIM(title) = '' THEN 'Title is blank or null'
            ELSE 'Title is present'
        END AS title_status
    FROM title
    WHERE 
        title IS NULL OR 
        TRIM(title) = ''
)

SELECT 
    nsm.id,
    nsm.title,
    nsm.title_status
FROM NullAndSpaceMovies nsm
WHERE nsm.title_status = 'Title is blank or null';

This SQL query complexly combines several constructs, including CTEs to establish separate logical groupings of data related to movies, casts, and keywords, while also presenting a query that factors in roles, keywords, and handles edge cases such as blank titles. Additionally, it demonstrates the use of window functions, correlated subqueries, and string aggregation, and provides an example of handling NULL logic uniquely.
