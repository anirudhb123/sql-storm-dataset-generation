WITH RecursiveMovies AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(c.name, 'Unknown') AS cast_name,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY c.nr_order) AS row_num
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name AS a ON c.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
),

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

RecentMovies AS (
    SELECT 
        DISTINCT m.movie_id,
        m.title,
        m.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COUNT(*) OVER () AS total_movies
    FROM 
        RecursiveMovies AS m
    LEFT JOIN 
        MovieKeywords AS mk ON m.movie_id = mk.movie_id
    WHERE 
        m.row_num <= 3 -- Limit to the top 3 casts for each production year
        AND m.production_year > 2000
),

null_check AS (
    SELECT 
        m.movie_id,
        CASE 
            WHEN m.keywords IS NULL THEN 'No Keywords Available'
            ELSE m.keywords
        END AS keywords,
        COALESCE(CAST(m.title AS TEXT), 'Untitled') AS movie_title,
        m.total_movies
    FROM 
        RecentMovies AS m
)

SELECT 
    n.movie_title,
    n.keywords,
    NULLIF(n.total_movies, 0) AS total_movies_count,
    ROW_NUMBER() OVER (ORDER BY n.movie_title) AS order_num,
    CASE 
        WHEN n.keywords LIKE '% Action %' THEN 'Action Packed!'
        WHEN n.keywords LIKE '% Drama %' THEN 'Drama Alert!'
        ELSE 'Genre Uncertain'
    END AS genre_annotation
FROM 
    null_check AS n
WHERE 
    n.total_movies IS NOT NULL
ORDER BY 
    n.total_movies_count DESC,
    n.movie_title;

WITH 
    AllMovieRoles AS (
        SELECT 
            m.id AS movie_id,
            a.name AS actor_name,
            r.role AS role_name,
            ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY a.name) AS role_order
        FROM 
            title AS m
        JOIN 
            cast_info AS c ON m.id = c.movie_id
        JOIN 
            aka_name AS a ON c.person_id = a.person_id
        JOIN 
            role_type AS r ON c.role_id = r.id
    )

SELECT 
    am.movie_id,
    STRING_AGG(DISTINCT CONCAT(am.actor_name, ' as ', am.role_name), ', ') AS full_cast,
    COUNT(*) FILTER (WHERE am.role_order = 1) AS lead_count
FROM 
    AllMovieRoles AS am
GROUP BY 
    am.movie_id
ORDER BY 
    lead_count DESC;
