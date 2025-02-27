WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        k.keyword AS genre,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title AS a
    JOIN 
        movie_keyword AS mk ON a.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        aka_name AS ak ON a.id = ak.person_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year, k.keyword
),

AggregatedRole AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT p.id) AS unique_actors,
        STRING_AGG(r.role, ', ') AS roles_played
    FROM 
        cast_info AS c
    JOIN 
        person_info AS p ON c.person_id = p.person_id
    JOIN 
        role_type AS r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
)

SELECT 
    RM.movie_title,
    RM.production_year,
    RM.aka_names,
    RM.genre,
    AR.unique_actors,
    AR.roles_played
FROM 
    RankedMovies AS RM
JOIN 
    AggregatedRole AS AR ON RM.id = AR.movie_id
WHERE 
    RM.rn = 1
ORDER BY 
    RM.production_year DESC, RM.movie_title;
