WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        wc.name AS company_name,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC, m.title) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name wc ON mc.company_id = wc.id
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
        AND m.production_year IS NOT NULL
), CastWithRoles AS (
    SELECT 
        c.movie_id,
        p.name AS actor_name,
        r.role AS role,
        c.nr_order
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        role_type r ON c.role_id = r.id
), MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    rm.company_name,
    cr.actor_name,
    cr.role,
    cr.nr_order,
    mk.keywords,
    COALESCE(NULLIF(cr.nr_order, 0), 'No Order') AS order_display, 
    CASE 
        WHEN rm.production_year < 2000 THEN 'Classic'
        WHEN rm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    CASE
        WHEN EXISTS (
            SELECT 1 
            FROM movie_info mi 
            WHERE mi.movie_id = rm.movie_id 
            AND mi.info_type_id = (SELECT id FROM info_type WHERE info LIKE '%Award%')
        ) THEN 'Awarded'
        ELSE 'Not Awarded'
    END AS award_status 
FROM 
    RankedMovies rm
LEFT JOIN 
    CastWithRoles cr ON rm.movie_id = cr.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC,
    rm.title,
    cr.nr_order NULLS LAST;
