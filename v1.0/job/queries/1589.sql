WITH MovieRoles AS (
    SELECT 
        c.movie_id, 
        r.role AS character_role,
        COUNT(c.id) AS cast_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COALESCE(mct.kind, 'Unknown') AS company_type
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type mct ON mc.company_type_id = mct.id
    GROUP BY 
        t.id, t.title, t.production_year, mct.kind
),
TopMovies AS (
    SELECT 
        md.movie_id, 
        md.title, 
        md.production_year,
        mr.character_role,
        mr.cast_count,
        RANK() OVER (PARTITION BY md.production_year ORDER BY mr.cast_count DESC) AS rank_in_year
    FROM 
        MovieDetails md
    JOIN 
        MovieRoles mr ON md.movie_id = mr.movie_id
    WHERE 
        md.production_year IS NOT NULL
)
SELECT 
    t.title, 
    t.production_year, 
    t.character_role, 
    t.cast_count,
    CASE 
        WHEN t.rank_in_year <= 3 THEN 'Top 3'
        ELSE 'Other'
    END AS ranking_group
FROM 
    TopMovies t
WHERE 
    t.rank_in_year <= 3 OR t.cast_count > 5
ORDER BY 
    t.production_year DESC, 
    t.cast_count DESC;
