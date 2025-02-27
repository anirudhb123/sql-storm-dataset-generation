WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
),
PeopleWithMostMovies AS (
    SELECT 
        c.person_id,
        COUNT(c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
    HAVING 
        COUNT(c.movie_id) >= 5
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    p.person_id,
    a.aka_name,
    r.movie_title,
    r.production_year,
    mk.keywords,
    p.movie_count
FROM 
    PeopleWithMostMovies p
JOIN 
    RankedTitles r ON p.person_id = r.aka_id
JOIN 
    MoviesWithKeywords mk ON r.movie_title = mk.movie_title
WHERE 
    r.rn = 1  -- Get only the latest movie for each person
ORDER BY 
    p.movie_count DESC, 
    r.production_year DESC;
