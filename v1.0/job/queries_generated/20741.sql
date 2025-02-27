WITH MovieStats AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order,
        STRING_AGG(DISTINCT c.name, ', ') FILTER (WHERE c.name IS NOT NULL) AS cast_names,
        COALESCE(MAX(CASE WHEN mi.info_type_id = 4 THEN mi.info END), 'Unknown genre') AS genre -- Assuming 4 is genre ID
    FROM
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_info mi ON t.movie_id = mi.movie_id
    GROUP BY 
        t.id
),
GenreStats AS (
    SELECT 
        genre,
        COUNT(movie_id) AS movie_count,
        AVG(total_cast) AS avg_cast_size,
        SUM(CASE WHEN avg_order > 2 THEN 1 ELSE 0 END) AS popular_movies
    FROM
        MovieStats
    GROUP BY 
        genre
),
TopGenres AS (
    SELECT 
        genre,
        movie_count,
        avg_cast_size,
        popular_movies,
        ROW_NUMBER() OVER (ORDER BY avg_cast_size DESC) AS rank
    FROM
        GenreStats
    WHERE 
        movie_count > 5
)

SELECT 
    g.genre,
    g.movie_count,
    g.avg_cast_size,
    g.popular_movies,
    Round(100.0 * g.popular_movies / g.movie_count, 2) AS popular_ratio, 
    CASE 
        WHEN g.movie_count >= 10 AND g.popular_movies > 5 THEN 'Top Tier'
        WHEN g.popular_movies > 0 THEN 'Emerging'
        ELSE 'Niche'
    END AS genre_category,
    t.title,
    t.cast_names,
    t.avg_order
FROM 
    TopGenres g
JOIN 
    MovieStats t ON g.genre = t.genre
ORDER BY 
    g.popular_ratio DESC 
LIMIT 10;

-- Investigating potential NULL discrepancies:
SELECT 
    c.id AS cast_id,
    c.name,
    c.md5sum,
    COUNT(DISTINCT ci.id) AS movie_roles
FROM 
    aka_name c
LEFT JOIN 
    cast_info ci ON c.person_id = ci.person_id 
GROUP BY 
    c.id, c.name, c.md5sum
HAVING 
    COUNT(DISTINCT ci.id) > 3 
    OR c.md5sum IS NULL
ORDER BY 
    movie_roles DESC;

-- Subquery checking if there are roles without corresponding names:
SELECT 
    ci.id AS cast_info_id,
    COUNT(*) AS missing_names
FROM 
    cast_info ci
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
WHERE 
    an.person_id IS NULL
GROUP BY 
    ci.id
HAVING 
    COUNT(*) > 0
ORDER BY 
    missing_names DESC;
