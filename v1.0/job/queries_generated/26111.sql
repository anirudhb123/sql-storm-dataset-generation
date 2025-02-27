WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title AS title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        mv.id AS movie_id,
        mv.title AS title,
        mv.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS aka_names,
        COUNT(DISTINCT c.person_id) AS cast_count,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords
    FROM 
        title mv
    JOIN 
        aka_title ak ON mv.id = ak.movie_id
    LEFT JOIN 
        cast_info c ON mv.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON mv.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mv.id, mv.title, mv.production_year
),
CastRoles AS (
    SELECT 
        c.movie_id,
        r.role AS role_name,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
FinalResults AS (
    SELECT 
        md.title,
        md.production_year,
        md.aka_names,
        md.cast_count,
        cr.role_name,
        cr.role_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        CastRoles cr ON md.movie_id = cr.movie_id
)

SELECT 
    fr.title,
    fr.production_year,
    fr.aka_names,
    fr.cast_count,
    fr.role_name,
    fr.role_count
FROM 
    FinalResults fr
WHERE 
    fr.production_year >= 2000
ORDER BY 
    fr.production_year DESC, fr.title;

This SQL query benchmarks string processing by extracting comprehensive details on movies produced from the year 2000 onwards, including alternative names (aka_names), the number of cast members involved (cast_count), and the roles they played (role_name) alongside their counts (role_count). The use of common table expressions (CTEs) optimizes and structures the query, making it maintainable and clear.
