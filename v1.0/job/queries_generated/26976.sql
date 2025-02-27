WITH MovieRoles AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        ARRAY_AGG(DISTINCT r.role) AS roles,
        COUNT(DISTINCT c.person_id) AS num_cast_members
    FROM 
        title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        m.id
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
FullMovieData AS (
    SELECT 
        mr.movie_id,
        mr.movie_title,
        mr.roles,
        mr.num_cast_members,
        mk.keywords
    FROM 
        MovieRoles mr
    LEFT JOIN 
        MovieKeywords mk ON mr.movie_id = mk.movie_id
)
SELECT 
    f.movie_title,
    f.num_cast_members,
    f.roles,
    f.keywords,
    COALESCE(REGEXP_MATCHES(f.movie_title, '^(.*?)(\s+)(.*)$'), ARRAY[NULL::text, NULL::text, NULL::text]) AS title_parts
FROM 
    FullMovieData f
WHERE 
    f.num_cast_members > 5
ORDER BY 
    f.num_cast_members DESC;
