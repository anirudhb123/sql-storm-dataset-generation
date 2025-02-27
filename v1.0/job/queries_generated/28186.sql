WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        COUNT(DISTINCT ci.person_id) AS num_cast_members
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id
),
TopTitles AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY num_cast_members DESC) AS rank
    FROM 
        RankedTitles
)
SELECT 
    tt.title,
    tt.production_year,
    tt.aka_names,
    tt.num_cast_members,
    JSON_AGG(JSON_BUILD_OBJECT('person_role', rt.role, 'cast_members', cm.cast_names)) AS detailed_cast
FROM 
    TopTitles tt
LEFT JOIN 
    cast_info ci ON tt.title_id = ci.movie_id
LEFT JOIN 
    role_type rt ON ci.person_role_id = rt.id
LEFT JOIN (
    SELECT 
        movie_id,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    GROUP BY 
        movie_id
) cm ON tt.title_id = cm.movie_id
WHERE 
    tt.rank <= 10
GROUP BY 
    tt.title, 
    tt.production_year, 
    tt.aka_names, 
    tt.num_cast_members
ORDER BY 
    tt.rank;
