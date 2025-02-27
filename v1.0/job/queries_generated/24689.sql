WITH RecursiveCTE AS (
    SELECT 
        a.id AS person_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.id, a.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
), 

MoviesWithKeyword AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        k.keyword AS keyword
    FROM 
        aka_title m
    INNER JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    INNER JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        k.keyword LIKE '%action%'
),

FilteredMovies AS (
    SELECT 
        mwk.movie_id,
        mwk.movie_title,
        ROW_NUMBER() OVER (PARTITION BY mwk.movie_id ORDER BY k.keyword) AS keyword_rank
    FROM 
        MoviesWithKeyword mwk
    JOIN 
        aka_title k ON mwk.movie_id = k.id
    WHERE 
        k.production_year > 2000
)

SELECT 
    c.actor_name,
    COUNT(DISTINCT fm.movie_id) AS action_movie_count,
    AVG(fm.keyword_rank) AS avg_keyword_rank
FROM 
    RecursiveCTE c
LEFT JOIN 
    FilteredMovies fm ON c.person_id IN (
        SELECT 
            cr.person_id
        FROM 
            cast_info cr
        WHERE 
            cr.movie_id = fm.movie_id
    )
GROUP BY 
    c.actor_name
HAVING 
    COUNT(DISTINCT fm.movie_id) >= 2
ORDER BY 
    action_movie_count DESC,
    avg_keyword_rank ASC;

WITH movie_stats AS (
    SELECT 
        title.title, 
        COUNT(DISTINCT ci.person_id) AS num_actors,
        SUM(CASE WHEN ci.nr_order IS NULL THEN 0 ELSE 1 END) AS ordered_roles
    FROM 
        title
    LEFT JOIN 
        cast_info ci ON ci.movie_id = title.id
    GROUP BY 
        title.title
),

TopMovies AS (
    SELECT 
        ms.title, 
        ms.num_actors, 
        ms.ordered_roles,
        ROW_NUMBER() OVER (ORDER BY ms.num_actors DESC, ms.ordered_roles DESC) AS rank
    FROM 
        movie_stats ms
    WHERE 
        ms.ordered_roles > 0
)

SELECT 
    tm.title, 
    tm.num_actors, 
    COALESCE(tm.ordered_roles, 0) AS adjusted_roles,
    CASE 
        WHEN tm.num_actors > 10 THEN 'Big Cast'
        WHEN tm.num_actors BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.num_actors DESC;

SELECT 
    (SELECT COUNT(*) 
     FROM aka_name a 
     WHERE a.name IS NOT NULL) AS NonNullActorCount,
    (SELECT COUNT(*) 
     FROM aka_name a 
     WHERE a.name IS NULL) AS NullActorCount,
    (SELECT COUNT(*) 
     FROM ak_title t 
     WHERE t.title IS NOT NULL) AS NonNullTitleCount,
    (SELECT COUNT(*) 
     FROM ak_title t 
     WHERE t.title IS NULL) AS NullTitleCount;

WITH LatestProductions AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        CAST(t.production_year AS INTEGER) AS year
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IN (SELECT MAX(production_year) FROM aka_title)
)

SELECT 
    lp.actor_name, 
    ARRAY_AGG(lp.movie_title) AS recent_movies
FROM 
    LatestProductions lp
GROUP BY 
    lp.actor_name
ORDER BY 
    lp.actor_name;
