WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_titles
    FROM
        aka_title t
    WHERE
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.role_id) AS num_roles,
        STRING_AGG(DISTINCT r.role, ', ') AS role_names
    FROM
        cast_info c
    JOIN
        role_type r ON c.role_id = r.id
    GROUP BY
        c.movie_id
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
EnhancedMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ar.num_roles, 0) AS num_roles,
        COALESCE(ar.role_names, 'No roles') AS role_names,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        CASE 
            WHEN rm.title_rank = 1 THEN 'First Title of Year'
            WHEN rm.title_rank = total_titles THEN 'Last Title of Year'
            ELSE 'Intermediate Title'
        END AS title_position
    FROM
        RankedMovies rm
    LEFT JOIN
        ActorRoles ar ON rm.movie_id = ar.movie_id
    LEFT JOIN
        MovieKeywords mk ON rm.movie_id = mk.movie_id
),
FilteredMovies AS (
    SELECT
        em.movie_id,
        em.title,
        em.production_year,
        em.num_roles,
        em.role_names,
        em.keywords,
        em.title_position
    FROM
        EnhancedMovies em
    WHERE
        em.production_year > 2000
        AND em.num_roles > 2
        AND em.role_names NOT LIKE '%unknown%'
        AND em.keywords IS NOT NULL
),
FinalOutput AS (
    SELECT
        f.*,
        CASE 
            WHEN f.production_year % 2 = 0 THEN 'Even Year'
            ELSE 'Odd Year'
        END AS year_class,
        CONCAT(f.title, ' - ', f.role_names) AS enhanced_title
    FROM
        FilteredMovies f
)

SELECT
    fo.movie_id,
    fo.title,
    fo.production_year,
    fo.num_roles,
    fo.role_names,
    fo.keywords,
    fo.title_position,
    fo.year_class,
    fo.enhanced_title
FROM
    FinalOutput fo
ORDER BY
    fo.production_year DESC, fo.title ASC;
