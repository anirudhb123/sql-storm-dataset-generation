
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
PeopleWithRoles AS (
    SELECT 
        ca.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(*) AS role_count
    FROM 
        cast_info ca
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    JOIN 
        role_type r ON ca.role_id = r.id
    GROUP BY 
        ca.movie_id, a.name, r.role
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title
),
CompleteCastMovies AS (
    SELECT 
        cc.movie_id,
        COUNT(cc.subject_id) AS total_cast
    FROM 
        complete_cast cc
    GROUP BY 
        cc.movie_id
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    rt.kind_id,
    pw.actor_name,
    pw.role_name,
    pw.role_count,
    mk.keywords,
    cm.total_cast
FROM 
    RankedTitles rt
LEFT JOIN 
    PeopleWithRoles pw ON rt.title_id = pw.movie_id
LEFT JOIN 
    MoviesWithKeywords mk ON rt.title_id = mk.movie_id
LEFT JOIN 
    CompleteCastMovies cm ON rt.title_id = cm.movie_id
WHERE 
    rt.title_rank <= 5
ORDER BY 
    rt.production_year DESC, rt.title ASC;
