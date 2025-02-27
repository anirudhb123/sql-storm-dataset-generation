WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_year,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actors_movie_count AS (
    SELECT
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS total_movies
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
company_movies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
movie_kw AS (
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
youngest_actor AS (
    SELECT
        pi.person_id,
        pi.info AS birth_year
    FROM 
        person_info pi
    WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'birth year')
        AND pi.info IS NOT NULL
        ORDER BY
        pi.info DESC
        LIMIT 1
)
SELECT 
    a.name AS actor_name,
    rt.title AS movie_title,
    rt.production_year,
    cm.company_name,
    cm.company_type,
    a_movie.total_movies,
    mw.keywords,
    CASE 
        WHEN rt.total_per_year > 10 THEN 'Prolific'
        ELSE 'Occasional'
    END AS release_style
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    ranked_titles rt ON ci.movie_id = rt.title_id
LEFT JOIN 
    company_movies cm ON ci.movie_id = cm.movie_id
LEFT JOIN 
    movie_kw mw ON ci.movie_id = mw.movie_id
JOIN 
    actors_movie_count a_movie ON ci.person_id = a_movie.person_id
WHERE 
    a.md5sum IS NOT NULL
AND 
    a.md5sum = (
        SELECT MAX(md5sum)
        FROM aka_name
        WHERE person_id = ci.person_id
    )
AND 
    rt.rank_year <= 5
AND 
    (a.name LIKE '%Smith%' OR a.name LIKE 'John%')
AND 
    ci.nr_order IS NOT NULL
ORDER BY 
    rt.production_year DESC, a.name;
