WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id ASC) AS rank_within_year,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Feature%')
),
TopDirectors AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT m.movie_id) AS num_movies
    FROM 
        cast_info c
    JOIN 
        movie_companies mc ON c.movie_id = mc.movie_id
    WHERE 
        c.role_id = (SELECT id FROM role_type WHERE role = 'Director')
    GROUP BY 
        c.person_id
    HAVING 
        COUNT(DISTINCT m.movie_id) > (SELECT AVG(num_movies) FROM (SELECT COUNT(DISTINCT movie_id) AS num_movies FROM cast_info WHERE role_id = (SELECT id FROM role_type WHERE role = 'Director') GROUP BY person_id) AS subquery)
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.rank_within_year,
    rm.total_movies_per_year,
    d.person_id AS director_id,
    CASE 
        WHEN d.person_id IS NOT NULL THEN (SELECT name FROM aka_name WHERE person_id = d.person_id ORDER BY id LIMIT 1)
        ELSE 'Unknown Director'
    END AS director_name,
    mk.keywords,
    CASE 
        WHEN rm.rank_within_year = 1 THEN 'Best Film of the Year'
        ELSE NULL
    END AS rank_status
FROM 
    RankedMovies rm
LEFT JOIN 
    cast_info c ON rm.movie_id = c.movie_id 
LEFT JOIN 
    TopDirectors d ON c.person_id = d.person_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.total_movies_per_year > 5 
    AND (rm.production_year < 2000 OR rm.production_year >= 2020)
    AND (mk.keywords IS NULL OR mk.keywords LIKE '%Action%')
ORDER BY 
    rm.production_year DESC, 
    rm.rank_within_year ASC
LIMIT 50;
