WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        aka_title AS t
    WHERE 
        t.kind_id IN (1, 2, 3) -- Example for filtering titles
),
CustomizedCast AS (
    SELECT 
        c.id AS cast_id,
        a.name AS actor_name,
        r.role AS role_name,
        t.title,
        t.production_year,
        COALESCE(m.note, 'No Note') AS movie_note
    FROM 
        cast_info AS c
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    JOIN 
        role_type AS r ON c.role_id = r.id
    JOIN 
        title AS t ON c.movie_id = t.id
    LEFT JOIN 
        movie_info AS m ON t.id = m.movie_id AND m.info_type_id = 1 -- Example info type
),
TopRoles AS (
    SELECT 
        actor_name,
        role_name,
        COUNT(*) AS num_roles
    FROM 
        CustomizedCast
    GROUP BY 
        actor_name, role_name
    HAVING 
        COUNT(*) > 1
)
SELECT 
    r.title,
    rc.actor_name,
    rc.role_name,
    rc.production_year,
    COALESCE(k.keyword, 'No Keyword') AS keyword,
    rc.movie_note
FROM 
    RankedTitles AS r
JOIN 
    CustomizedCast AS rc ON r.title = rc.title AND r.production_year = rc.production_year
LEFT JOIN 
    movie_keyword AS mk ON rc.title = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
WHERE 
    r.rank <= 5 -- Top 5 ranked titles by production year
ORDER BY 
    r.production_year DESC, rc.actor_name;
