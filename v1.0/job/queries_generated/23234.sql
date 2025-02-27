WITH MovieStats AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS total_cast,
        AVG(ci.nr_order) AS avg_order,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
        AND t.title IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
), PopularGenres AS (
    SELECT 
        COUNT(m.id) AS genre_count,
        kt.kind AS genre
    FROM 
        aka_title m
    JOIN 
        kind_type kt ON m.kind_id = kt.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        kt.kind
), AvgRoleDistribution AS (
    SELECT 
        ci.role_id,
        r.role,
        AVG(COALESCE(ci.nr_order, 0)) AS avg_role_order
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.role_id, r.role
), HighRatedMovies AS (
    SELECT 
        t.title, 
        t.production_year,
        COALESCE(m.rating, 0) AS rating
    FROM 
        aka_title t
    LEFT JOIN 
        movie_info m ON t.id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    WHERE 
        COALESCE(m.rating, 0) > 8.0
)

SELECT 
    ms.title AS Movie_Title,
    ms.production_year AS Production_Year,
    ms.total_cast AS Total_Cast,
    ms.avg_order AS Average_Cast_Order,
    ms.keywords AS Associated_Keywords,
    hg.rating AS Rating,
    pg.genre AS Popular_Genre
FROM 
    MovieStats ms
JOIN 
    HighRatedMovies hg ON ms.title = hg.title AND ms.production_year = hg.production_year
LEFT JOIN 
    PopularGenres pg ON pg.genre_count = (
        SELECT MAX(genre_count) FROM PopularGenres
    )
WHERE 
    (ms.total_cast > 5 OR ms.avg_order < 3)
    AND NOT EXISTS (
        SELECT 1 FROM movie_info mi 
        WHERE mi.movie_id = ms.title_id AND mi.info LIKE '%directed%'
    )
ORDER BY 
    ms.production_year DESC, 
    hg.rating DESC;
