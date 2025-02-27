WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        t.title,
        a.name AS actor_name,
        c.kind AS role,
        m.note AS movie_note,
        k.keyword AS movie_keyword
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        comp_cast_type c ON ci.person_role_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        movie_info_idx mii ON mi.id = mii.id
    LEFT JOIN 
        movie_info m ON t.id = m.movie_id
    WHERE 
        cn.id IS NOT NULL
)
SELECT 
    md.title,
    md.actor_name,
    md.role,
    COALESCE(md.movie_note, 'No Note') AS movie_note,
    md.movie_keyword,
    rm.production_year
FROM 
    MovieDetails md
JOIN 
    RankedMovies rm ON md.title = rm.title AND rm.rn = 1
WHERE 
    md.role IS NOT NULL
ORDER BY 
    rm.production_year DESC, md.title;
