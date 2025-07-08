
WITH RankedMovieTitles AS (
    SELECT 
        a.id AS title_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank
    FROM 
        aka_title a
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%movie%')
),
PersonMovieRoles AS (
    SELECT 
        c.movie_id,
        p.name AS person_name,
        r.role AS role_name,
        COUNT(*) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, p.name, r.role
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
MovieInfoWithCompanies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        c.name AS company_name,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        MoviesWithKeywords mk ON m.id = mk.movie_id
    WHERE 
        m.production_year >= 2000
)
SELECT 
    rmt.title,
    rmt.production_year,
    p.person_name,
    p.role_name,
    mc.movie_id,
    mc.company_name,
    mc.keywords
FROM 
    RankedMovieTitles rmt
JOIN 
    PersonMovieRoles p ON rmt.title_id = p.movie_id
JOIN 
    MovieInfoWithCompanies mc ON rmt.title_id = mc.movie_id
WHERE 
    rmt.rank <= 5 
ORDER BY 
    rmt.production_year DESC, 
    rmt.title,
    p.role_count DESC;
