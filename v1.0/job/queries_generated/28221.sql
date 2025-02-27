WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER(PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
),
ActorsWithRoleCount AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS role_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.person_role_id = r.id
    GROUP BY 
        ci.person_id
),
MovieWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    t.title,
    t.production_year,
    r.roles,
    mk.keywords
FROM 
    RankedTitles t
JOIN 
    ActorsWithRoleCount r ON t.title_id IN (
        SELECT movie_id 
        FROM cast_info WHERE person_id IN (
            SELECT person_id FROM ActorsWithRoleCount WHERE role_count > 1
        )
    )
JOIN 
    MovieWithKeywords mk ON t.title_id = mk.movie_id
WHERE 
    t.rank <= 5
ORDER BY 
    t.production_year DESC, t.title;
