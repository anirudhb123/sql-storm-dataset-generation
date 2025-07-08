
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM aka_title t
    WHERE t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        LISTAGG(DISTINCT r.role, ', ') WITHIN GROUP (ORDER BY r.role) AS roles_played
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY a.person_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS companies
    FROM movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    GROUP BY mc.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    a.movie_count AS actor_movie_count,
    a.roles_played,
    k.keywords,
    c.companies,
    CASE 
        WHEN r.total_movies > 1 THEN 'Featured'
        ELSE 'Single Feature'
    END AS movie_status
FROM RankedMovies r
LEFT JOIN ActorRoles a ON r.movie_id = a.person_id
LEFT JOIN MovieKeywords k ON r.movie_id = k.movie_id
LEFT JOIN CompanyMovies c ON r.movie_id = c.movie_id
WHERE 
    r.rn <= 5 AND
    (r.production_year > 2000 OR c.companies IS NOT NULL) 
ORDER BY 
    r.production_year DESC, 
    r.title;
