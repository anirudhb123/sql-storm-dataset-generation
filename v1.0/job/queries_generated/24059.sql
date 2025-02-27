WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY r.rating DESC NULLS LAST) AS rank,
        r.rating,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT CONCAT(p.name, ' (', ct.kind, ')'), ', ') AS cast_members
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name p ON ci.person_id = p.person_id
    LEFT JOIN 
        comp_cast_type ct ON ci.role_id = ct.id
    LEFT JOIN 
        (SELECT 
            movie_id, 
            AVG(rating) AS rating 
         FROM 
            movie_info mi
         WHERE 
            info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
         GROUP BY 
            movie_id) r ON a.id = r.movie_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year, r.rating
),
NullHandling AS (
    SELECT 
        *,
        COALESCE(rank, (SELECT MAX(rank) FROM RankedMovies)) AS adjusted_rank
    FROM 
        RankedMovies
)
SELECT 
    nm.name AS actor_name,
    nm.imdb_index AS actor_imdb_index,
    COUNT(DISTINCT tt.title) AS titles_appeared_in,
    AVG(COALESCE(NULLIF(m.production_year, 0), 2023)) AS avg_year_of_movies
FROM 
    aka_name nm
LEFT JOIN 
    cast_info ci ON nm.person_id = ci.person_id
LEFT JOIN 
    aka_title tt ON ci.movie_id = tt.id
LEFT JOIN 
    NullHandling m ON tt.id = m.id
WHERE 
    nm.name IS NOT NULL AND 
    nm.name NOT LIKE '%N/A%'
GROUP BY 
    nm.name, nm.imdb_index
ORDER BY 
    titles_appeared_in DESC, 
    actor_name NULLS FIRST
FETCH FIRST 10 ROWS ONLY;
