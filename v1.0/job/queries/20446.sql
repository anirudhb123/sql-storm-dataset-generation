WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM aka_title a
    LEFT JOIN cast_info c ON a.movie_id = c.movie_id
    GROUP BY a.id, a.title, a.production_year
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords,
        COUNT(k.keyword) AS keyword_count
    FROM movie_keyword m
    JOIN keyword k ON m.keyword_id = k.id
    GROUP BY m.movie_id
),
FilteredMovies AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        r.actor_count,
        coalesce(mk.keywords, 'No Keywords') AS keywords,
        mk.keyword_count
    FROM RankedMovies r
    LEFT JOIN MovieKeywords mk ON r.movie_id = mk.movie_id
    WHERE r.rank <= 5 
),
ActorRoles AS (
    SELECT 
        p.id AS person_id,
        a.movie_id,
        p.name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY a.movie_id ORDER BY p.name) AS role_rank
    FROM cast_info a
    JOIN aka_name p ON a.person_id = p.person_id
    JOIN role_type r ON a.role_id = r.id
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.actor_count,
    f.keywords,
    f.keyword_count,
    ARRAY_AGG(DISTINCT ar.role_name) AS roles,
    SUM(CASE WHEN ar.role_rank < 3 THEN 1 ELSE 0 END) AS top_roles_count
FROM FilteredMovies f
LEFT JOIN ActorRoles ar ON f.movie_id = ar.movie_id
GROUP BY f.movie_id, f.title, f.production_year, f.actor_count, f.keywords, f.keyword_count
ORDER BY f.production_year DESC, f.actor_count DESC;