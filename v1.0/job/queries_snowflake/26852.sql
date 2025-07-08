
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
TitleKeyword AS (
    SELECT 
        mt.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        LISTAGG(CONCAT(a.name, ' as ', rt.role), ', ') WITHIN GROUP (ORDER BY a.name) AS roles
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type rt ON c.role_id = rt.id
    GROUP BY 
        c.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    tk.keywords,
    ar.roles
FROM 
    RankedTitles rt
LEFT JOIN 
    TitleKeyword tk ON rt.title_id = tk.movie_id
LEFT JOIN 
    ActorRoles ar ON rt.title_id = ar.movie_id
WHERE 
    rt.title_rank <= 5  
ORDER BY 
    rt.production_year DESC, rt.title ASC;
