WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        r.role AS actor_role,
        a.name AS actor_name,
        COUNT(c.id) AS cast_member_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        t.production_year >= 2000
        AND k.keyword LIKE '%action%'
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, r.role, a.name
),
TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        movie_keyword,
        actor_name,
        cast_member_count,
        RANK() OVER (ORDER BY cast_member_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.movie_keyword,
    STRING_AGG(DISTINCT tm.actor_name, ', ') AS actor_names,
    tm.cast_member_count
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.movie_id, tm.movie_title, tm.production_year, tm.movie_keyword, tm.cast_member_count
ORDER BY 
    tm.cast_member_count DESC;
