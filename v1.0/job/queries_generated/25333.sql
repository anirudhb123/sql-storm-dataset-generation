WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        num_cast,
        keywords
    FROM RankedMovies
    WHERE rank <= 5
)
SELECT 
    m.title,
    m.production_year,
    m.num_cast,
    m.keywords,
    COALESCE(AKA.name, 'N/A') AS aka_name,
    COALESCE(p.info, 'No additional info') AS person_info
FROM TopMovies m
LEFT JOIN aka_title AKA ON m.movie_id = AKA.movie_id
LEFT JOIN cast_info c ON m.movie_id = c.movie_id
LEFT JOIN person_info p ON c.person_id = p.person_id
ORDER BY m.production_year DESC, m.num_cast DESC;
