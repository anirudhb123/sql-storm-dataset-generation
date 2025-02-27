WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.rating DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    WHERE 
        t.production_year IS NOT NULL
),
CastAndCrew AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(DISTINCT cc.person_id) AS total_cast
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        complete_cast cc ON c.movie_id = cc.movie_id
    GROUP BY 
        c.movie_id, a.name, r.role
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
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(a.actor_name, 'Unknown') AS lead_actor,
    CASE 
        WHEN rm.rank <= 5 THEN 'Top 5 Movies of the Year'
        ELSE 'Other Movies'
    END AS movie_category,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    CAST(ac.total_cast AS INTEGER) AS total_cast_members
FROM 
    RankedMovies rm
LEFT JOIN 
    CastAndCrew ac ON rm.movie_id = ac.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rank <= 10 OR mk.keywords IS NOT NULL
ORDER BY 
    rm.production_year DESC, rm.rank;
