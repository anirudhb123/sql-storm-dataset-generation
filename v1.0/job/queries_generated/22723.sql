WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY MAX(c.nr_order) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorRoles AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        STRING_AGG(r.role, ', ') AS roles
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        a.id, a.name
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FilteredMovies AS (
    SELECT 
        DISTINCT RM.movie_id, 
        RM.title,
        RM.production_year,
        AR.actor_name,
        AR.roles,
        COALESCE(MK.keywords, 'No keywords') AS keywords
    FROM 
        RankedMovies RM
    LEFT JOIN 
        ActorRoles AR ON RM.movie_id IN (
            SELECT 
                ci.movie_id 
            FROM 
                cast_info ci 
            WHERE 
                ci.person_role_id IN (SELECT id FROM role_type WHERE role LIKE '%Actor%')
        )
    LEFT JOIN 
        MovieKeywords MK ON RM.movie_id = MK.movie_id
    WHERE 
        RM.production_year >= 2000 -- Filter for movies produced from the year 2000 onwards
        AND RM.movie_id NOT IN (SELECT movie_id FROM movie_info WHERE info_type_id = 1 AND info = 'N/A') -- Exclude movies with 'N/A' info
        AND EXISTS (SELECT 1 FROM movie_companies mc WHERE mc.movie_id = RM.movie_id AND mc.note IS NULL) -- Ensure the movie has a company with no notes
)
SELECT 
    FM.movie_id, 
    FM.title, 
    FM.production_year, 
    FM.actor_name, 
    FM.roles, 
    FM.keywords
FROM 
    FilteredMovies FM
WHERE 
    FM.role IS NOT NULL
ORDER BY 
    FM.production_year DESC, FM.title ASC;
