WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT title, production_year 
    FROM RankedMovies 
    WHERE rank <= 5
),
ActorsWithMultipleRoles AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM 
        aka_name a
    INNER JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(DISTINCT ci.role_id) > 1
),
MovieKeywords AS (
    SELECT 
        mt.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
QualifiedMovies AS (
    SELECT 
        tm.title, 
        tm.production_year,
        mk.keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywords mk ON tm.movie_id = mk.movie_id
)
SELECT 
    q.title,
    q.production_year,
    COALESCE(q.keywords, 'No Keywords') AS keywords,
    COALESCE(a.role_count, 0) AS actor_role_count
FROM 
    QualifiedMovies q 
LEFT JOIN 
    ActorsWithMultipleRoles a ON EXISTS (
        SELECT 1 
        FROM cast_info ci 
        WHERE ci.movie_id = q.movie_id AND ci.person_id = a.person_id
    )
ORDER BY 
    q.production_year DESC,
    q.title ASC;

