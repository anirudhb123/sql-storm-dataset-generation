WITH RankedMovies AS (
    SELECT 
        a.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rank
    FROM 
        aka_title at
    INNER JOIN 
        title a ON at.movie_id = a.id
    WHERE 
        at.production_year IS NOT NULL
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
CastRoles AS (
    SELECT
        cc.movie_id,
        STRING_AGG(DISTINCT r.role, ', ') AS roles,
        COUNT(DISTINCT c.person_id) AS number_of_cast
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        complete_cast cc ON c.movie_id = cc.movie_id
    GROUP BY 
        cc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(cr.roles, 'No Roles') AS roles,
    cr.number_of_cast,
    CASE 
        WHEN rm.production_year < 2000 THEN 'Old Movie'
        WHEN rm.production_year BETWEEN 2000 AND 2015 THEN 'Modern Movie'
        ELSE 'Recent Movie'
    END AS movie_age_category
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.id = mk.movie_id
LEFT JOIN 
    CastRoles cr ON rm.id = cr.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title;
