WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank
    FROM 
        aka_title a 
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
),
ThemedCasts AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(c.person_id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
    HAVING 
        COUNT(c.person_id) > 1
),
CompleteData AS (
    SELECT 
        r.title,
        r.production_year,
        t.role,
        t.role_count,
        COUNT(DISTINCT ca.person_id) AS unique_cast_members
    FROM 
        RankedTitles r
    JOIN 
        Complete_Cast ca ON ca.movie_id = r.id
    JOIN 
        ThemedCasts t ON t.movie_id = ca.movie_id
    GROUP BY 
        r.title, r.production_year, t.role, t.role_count
)
SELECT 
    title,
    production_year,
    role,
    role_count,
    unique_cast_members
FROM 
    CompleteData
WHERE 
    unique_cast_members > 5
ORDER BY 
    production_year DESC, title;
