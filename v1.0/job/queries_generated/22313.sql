WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
CoStars AS (
    SELECT 
        c1.person_id,
        c1.movie_id,
        STRING_AGG(DISTINCT c2.person_id::TEXT, ', ') AS co_stars
    FROM 
        cast_info c1
    JOIN 
        cast_info c2 ON c1.movie_id = c2.movie_id AND c1.person_id <> c2.person_id
    GROUP BY 
        c1.person_id, c1.movie_id
),
MovieInfoWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        STRING_AGG(kw.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        m.id, m.title
),
PersonRoles AS (
    SELECT 
        a.name,
        COALESCE(r.role, 'Unknown') AS role,
        COUNT(c.id) AS movie_count
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        a.name, r.role
    HAVING 
        COUNT(c.id) > 2
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    c.person_id AS co_star_id,
    c.co_stars,
    kw.keywords,
    p.name AS actor_name,
    p.role,
    p.movie_count
FROM 
    RankedMovies rm
LEFT JOIN 
    CoStars c ON rm.movie_id = c.movie_id
LEFT JOIN 
    MovieInfoWithKeywords kw ON rm.movie_id = kw.movie_id
LEFT JOIN 
    PersonRoles p ON c.person_id = p.name
WHERE 
    rm.rank = 1
    AND (kw.keywords IS NOT NULL OR c.co_stars IS NOT NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
