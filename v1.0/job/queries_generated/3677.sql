WITH MovieRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
PopularMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(r.role_count, 0) AS role_count
    FROM 
        aka_title m
    LEFT JOIN 
        MovieRoles r ON m.id = r.movie_id
    WHERE 
        m.production_year > 2000
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        role_count,
        RANK() OVER (ORDER BY role_count DESC) AS rank
    FROM 
        PopularMovies
    WHERE 
        role_count > 5
)
SELECT 
    tm.title,
    COALESCE(cn.name, 'Unknown') AS company_name,
    m.production_year,
    EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = tm.movie_id 
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis') 
        AND mi.info IS NOT NULL
    ) AS has_synopsis,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    cn.country_code IS NOT NULL AND 
    cn.name IS NOT NULL
GROUP BY 
    tm.movie_id, tm.title, cn.name, m.production_year
HAVING 
    COUNT(DISTINCT mk.keyword_id) > 2
ORDER BY 
    tm.rank;
