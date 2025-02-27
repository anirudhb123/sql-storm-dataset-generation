WITH RankedTitles AS (
    SELECT 
        t.id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY ts.title_length DESC) AS rank_within_year,
        LENGTH(t.title) AS title_length
    FROM 
        aka_title t
    JOIN (
        SELECT 
            title_id, 
            LENGTH(title) AS title_length
        FROM 
            aka_title
    ) ts ON ts.title_id = t.id
),

CompanyMovies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id 
    JOIN 
        company_type ct ON mc.company_type_id = ct.id 
    LEFT JOIN 
        cast_info ci ON mc.movie_id = ci.movie_id 
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),

FamousActors AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS film_count,
        MAX(t.production_year) AS latest_movie_year
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 10
)

SELECT 
    rt.title,
    rt.production_year,
    cm.company_name,
    cm.company_type,
    fa.actor_name,
    fa.film_count,
    fa.latest_movie_year
FROM 
    RankedTitles rt
LEFT JOIN 
    CompanyMovies cm ON rt.id = cm.movie_id
LEFT JOIN 
    FamousActors fa ON fa.latest_movie_year <= rt.production_year 
WHERE 
    rt.rank_within_year <= 3
    AND (cm.cast_count IS NULL OR cm.cast_count > 0)
ORDER BY 
    rt.production_year DESC,
    rt.title ASC;

-- Second part with a more bizarre selection using NULL logic and outer joins
SELECT DISTINCT 
    t.title,
    COALESCE(fa.actor_name, 'Unknown Actor') AS actor_name,
    CASE 
        WHEN fa.film_count IS NULL THEN 'Low Performer'
        WHEN fa.film_count BETWEEN 1 AND 5 THEN 'Average Performer'
        ELSE 'High Performer'
    END AS performance_category
FROM 
    aka_title t
LEFT JOIN 
    cast_info ci ON t.id = ci.movie_id
LEFT JOIN 
    aka_name fa ON ci.person_id = fa.person_id
WHERE 
    t.production_year IS NOT NULL
    AND (t.note IS NULL OR t.note NOT LIKE '%unlisted%')
    AND EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = t.id 
        AND mi.info_type_id IS NOT NULL
    )
ORDER BY 
    t.production_year DESC, 
    performance_category ASC;

-- Final part with a set operation showing movies with various and bizarre conditions
SELECT 
    t.title AS Movies_In_2000s
FROM 
    aka_title t
WHERE 
    t.production_year >= 2000 AND t.production_year < 2010

UNION 

SELECT 
    t.title AS Movies_Without_A_Leading_Actor
FROM 
    aka_title t
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM cast_info ci 
        WHERE ci.movie_id = t.id 
        AND ci.nr_order = 1
    )
ORDER BY 
    Movies_In_2000s;
