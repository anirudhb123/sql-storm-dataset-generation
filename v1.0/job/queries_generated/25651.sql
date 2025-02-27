WITH RankedTitles AS (
    SELECT 
        t.title AS movie_title, 
        t.production_year, 
        k.keyword AS keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS rn
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
CastDetails AS (
    SELECT 
        c.movie_id, 
        a.name AS actor_name, 
        p.gender, 
        r.role AS acting_role
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        name p ON a.person_id = p.imdb_id
),
MovieInfoSummary AS (
    SELECT 
        m.movie_id, 
        COUNT(DISTINCT i.info_type_id) AS info_type_count, 
        STRING_AGG(DISTINCT i.info, ', ') AS details
    FROM 
        movie_info m
    JOIN 
        info_type i ON m.info_type_id = i.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rt.movie_title, 
    rt.production_year, 
    STRING_AGG(DISTINCT cd.actor_name || ' (' || cd.acting_role || ')', '; ') AS actors,
    mis.info_type_count,
    mis.details,
    STRING_AGG(DISTINCT rt.keyword, ', ') AS keywords
FROM 
    RankedTitles rt
JOIN 
    CastDetails cd ON rt.movie_title = cd.movie_id
JOIN 
    MovieInfoSummary mis ON rt.id = mis.movie_id
GROUP BY 
    rt.movie_title, rt.production_year
ORDER BY 
    rt.production_year DESC, rt.movie_title;
