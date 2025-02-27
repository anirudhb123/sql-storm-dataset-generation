WITH RankedTitles AS (
    SELECT 
        t.title,
        ak.name AS aka_name,
        c.person_role_id,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS rank
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS c ON t.movie_id = c.movie_id
    JOIN 
        aka_name AS ak ON c.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
),
MovieStats AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COUNT(DISTINCT c.id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        MAX(t.production_year) AS latest_year
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS c ON t.movie_id = c.movie_id
    JOIN 
        aka_name AS ak ON c.person_id = ak.person_id
    GROUP BY 
        t.id, t.title
),
AkaRoleCounts AS (
    SELECT 
        ak.name AS aka_name,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        MAX(m.production_year) AS latest_movie_year
    FROM 
        aka_name AS ak
    JOIN 
        cast_info AS c ON ak.person_id = c.person_id
    JOIN 
        aka_title AS m ON c.movie_id = m.movie_id
    GROUP BY 
        ak.name
)
SELECT 
    ms.title,
    ms.total_cast,
    ms.cast_names,
    arc.aka_name,
    arc.total_movies,
    arc.latest_movie_year,
    rt.person_role_id,
    rt.rank
FROM 
    MovieStats AS ms
JOIN 
    AkaRoleCounts AS arc ON arc.total_movies > 5
LEFT JOIN 
    RankedTitles AS rt ON rt.title = ms.title
ORDER BY 
    ms.latest_year DESC, ms.title;
