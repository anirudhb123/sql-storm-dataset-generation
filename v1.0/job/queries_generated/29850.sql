WITH MovieCounts AS (
    SELECT 
        a.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.movie_id
),
TopMovies AS (
    SELECT 
        m.movie_id,
        m.actor_count,
        m.company_count,
        m.keywords,
        ROW_NUMBER() OVER (ORDER BY m.actor_count DESC, m.company_count DESC) AS rank
    FROM 
        MovieCounts m
    WHERE 
        m.actor_count > 5 AND m.company_count > 3
)
SELECT 
    a.title AS movie_title,
    COUNT(DISTINCT c.person_id) AS total_actors,
    GROUP_CONCAT(DISTINCT nm.name) AS actor_names,
    GROUP_CONCAT(DISTINCT co.name) AS production_companies,
    tm.keywords
FROM 
    aka_title a
JOIN 
    cast_info c ON a.id = c.movie_id
JOIN 
    name nm ON c.person_id = nm.imdb_id
JOIN 
    movie_companies mc ON a.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    TopMovies tm ON a.id = tm.movie_id
WHERE 
    tm.rank <= 10
GROUP BY 
    a.title, tm.keywords
ORDER BY 
    total_actors DESC, a.title ASC;
