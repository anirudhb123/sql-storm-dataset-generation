
WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        t.id AS movie_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_per_year
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
        AND t.production_year > 2000
),
AllPeople AS (
    SELECT
        a.id AS aka_id,
        a.person_id,
        n.name,
        n.gender,
        COUNT(c.movie_id) AS movies_count
    FROM
        aka_name a
    JOIN
        name n ON a.person_id = n.id
    LEFT JOIN
        cast_info c ON a.person_id = c.person_id
    GROUP BY
        a.id, a.person_id, n.name, n.gender
    HAVING
        COUNT(c.movie_id) > 1
),
MoviesWithKeywords AS (
    SELECT
        m.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        aka_title m ON mk.movie_id = m.id
    WHERE
        k.keyword IS NOT NULL
    GROUP BY
        m.movie_id, k.keyword
),
FilteredMovies AS (
    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(k.keyword, 'No Keywords') AS keyword
    FROM
        RankedMovies m
    LEFT JOIN
        MoviesWithKeywords k ON m.movie_id = k.movie_id
    WHERE
        m.rank_per_year <= 5
)
SELECT 
    p.name AS actor_name,
    p.gender,
    COUNT(DISTINCT f.movie_id) AS movies_participated,
    LISTAGG(DISTINCT f.title, ', ') WITHIN GROUP (ORDER BY f.title) AS titles,
    f.keyword
FROM 
    AllPeople p
JOIN 
    cast_info ci ON p.person_id = ci.person_id
JOIN 
    FilteredMovies f ON ci.movie_id = f.movie_id
GROUP BY 
    p.name, p.gender, f.keyword
HAVING 
    COUNT(DISTINCT f.movie_id) > 2
ORDER BY 
    movies_participated DESC, p.name ASC;
