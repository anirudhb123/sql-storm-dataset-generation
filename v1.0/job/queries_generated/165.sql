WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS year_rank
    FROM 
        aka_title t
),
ExtendedInfo AS (
    SELECT 
        m.movie_id,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        COALESCE(ci.role_id, -1) AS role_id,
        COUNT(DISTINCT ci.person_id) AS num_cast_members
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON m.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        m.movie_id, k.keyword, ci.role_id
),
HighProfileMovies AS (
    SELECT 
        e.movie_id,
        e.keyword,
        e.num_cast_members,
        CASE 
            WHEN e.num_cast_members > 5 THEN 'High Profile'
            WHEN e.num_cast_members IS NULL THEN 'Unknown Profile'
            ELSE 'Regular Profile'
        END AS movie_profile
    FROM 
        ExtendedInfo e
    WHERE 
        e.num_cast_members IS NOT NULL
)
SELECT 
    h.movie_id,
    h.keyword,
    h.movie_profile,
    COUNT(DISTINCT c.person_id) AS total_people,
    STRING_AGG(DISTINCT p.info ORDER BY p.info) AS person_info
FROM 
    HighProfileMovies h
LEFT JOIN 
    cast_info c ON h.movie_id = c.movie_id
LEFT JOIN 
    person_info p ON c.person_id = p.person_id
GROUP BY 
    h.movie_id, h.keyword, h.movie_profile
HAVING 
    COUNT(DISTINCT c.person_id) > 0
ORDER BY 
    h.movie_id;
