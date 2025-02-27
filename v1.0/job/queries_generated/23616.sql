WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ak.name AS actor_name,
        rc.movie_id,
        rt.role,
        COUNT(*) OVER (PARTITION BY rc.role_id) AS role_count
    FROM 
        cast_info rc
    INNER JOIN aka_name ak ON ak.person_id = rc.person_id
    LEFT JOIN role_type rt ON rt.id = rc.role_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieInfoDetails AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'description' THEN mi.info END) AS movie_description,
        MAX(CASE WHEN it.info = 'rating' THEN mi.info END) AS movie_rating
    FROM 
        movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.title_id,
    rm.title,
    rm.production_year,
    ak.actor_name,
    ar.role,
    mk.keywords,
    mid.movie_description,
    mid.movie_rating,
    COALESCE(ar.role_count, 0) AS actor_role_count,
    CASE 
        WHEN mid.movie_rating IS NOT NULL AND mid.movie_rating::numeric < 5 THEN 'Low Rated'
        WHEN mid.movie_rating IS NULL THEN 'No Rating'
        ELSE 'Rated'
    END AS rating_status
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON ar.movie_id = rm.title_id
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = rm.title_id
LEFT JOIN 
    MovieInfoDetails mid ON mid.movie_id = rm.title_id
WHERE 
    rm.rank <= 5
    AND (ar.role IS NULL OR ar.role NOT IN (SELECT role FROM role_type WHERE role = 'Cameo'))
ORDER BY 
    rm.production_year DESC, 
    ar.actor_name;
