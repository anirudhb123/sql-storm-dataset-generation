WITH Filmography AS (
    SELECT
        a.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        ck.kind AS company_kind,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS film_rank,
        COUNT(*) OVER (PARTITION BY a.person_id) as total_films
    FROM
        aka_name AS a
    JOIN
        cast_info AS c ON a.person_id = c.person_id
    JOIN
        aka_title AS t ON c.movie_id = t.movie_id
    LEFT JOIN
        movie_companies AS mc ON t.id = mc.movie_id
    LEFT JOIN
        company_type AS ck ON mc.company_type_id = ck.id
    WHERE
        t.production_year IS NOT NULL
        AND ck.kind IS NOT NULL
        AND EXISTS (
            SELECT 1
            FROM role_type AS rt
            WHERE rt.id = c.role_id
            AND rt.role ILIKE '%actor%'
        )
),
TopActors AS (
    SELECT
        person_id,
        actor_name,
        film_title,
        film_rank,
        total_films
    FROM
        Filmography
    WHERE
        film_rank <= 5
)
SELECT 
    ta.actor_name,
    ta.total_films,
    STRING_AGG(DISTINCT ta.movie_title || ' (' || ta.production_year || ')', ', ') AS filmography,
    NULLIF(MAX(CASE WHEN kc.keyword LIKE '%blockbuster%' THEN 1 END), 0) AS has_blockbuster
FROM
    TopActors AS ta
LEFT JOIN 
    movie_keyword AS mk ON mk.movie_id IN (
        SELECT movie_id 
        FROM aka_title 
        WHERE id IN (
            SELECT DISTINCT movie_id 
            FROM cast_info 
            WHERE person_id = ta.person_id
        )
    )
LEFT JOIN 
    keyword AS kc ON mk.keyword_id = kc.id
GROUP BY
    ta.actor_name, ta.total_films
HAVING
    COUNT(DISTINCT ta.movie_title) > 2
ORDER BY 
    ta.total_films DESC
LIMIT 10;

-- Additional benchmarking for optimization via join types
EXPLAIN ANALYZE
SELECT 
    DISTINCT a.name,
    COUNT(c.movie_id) AS movie_count,
    COUNT(DISTINCT CASE WHEN mc.company_id IS NOT NULL THEN mc.company_id END) AS unique_company_count
FROM
    aka_name a
LEFT JOIN 
    cast_info c ON a.person_id = c.person_id
LEFT JOIN 
    movie_companies mc ON c.movie_id = mc.movie_id
WHERE 
    a.name IS NOT NULL
    AND (SELECT COUNT(*) FROM title t WHERE t.kind_id IS NOT NULL AND t.production_year > 2000) > 100
GROUP BY 
    a.name
HAVING 
    COUNT(c.movie_id) > 5
ORDER BY 
    movie_count DESC
LIMIT 20;
